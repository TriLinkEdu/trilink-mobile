import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/chat_models.dart';
import 'student_chat_repository.dart';

class RealStudentChatRepository implements StudentChatRepository {
  final ApiClient _api;
  final StorageService _storage;

  static const Duration _conversationsTtl = Duration(seconds: 20);
  static const Duration _messagesTtl = Duration(seconds: 10);

  static List<ChatConversationModel>? _conversationsCache;
  static DateTime? _conversationsFetchedAt;
  static Future<List<ChatConversationModel>>? _conversationsInFlight;

  static final Map<String, List<ChatMessageModel>> _messagesCache =
      <String, List<ChatMessageModel>>{};
  static final Map<String, DateTime> _messagesFetchedAt = <String, DateTime>{};
  static final Map<String, Future<List<ChatMessageModel>>> _messagesInFlight =
      <String, Future<List<ChatMessageModel>>>{};

  RealStudentChatRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<List<ChatConversationModel>> fetchConversations() async {
    if (_conversationsCache != null && _conversationsFetchedAt != null) {
      final age = DateTime.now().difference(_conversationsFetchedAt!);
      if (age < _conversationsTtl) return _conversationsCache!;
    }

    final inFlight = _conversationsInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchConversationsFresh();
    _conversationsInFlight = future;
    final data = await future;
    _conversationsInFlight = null;
    _conversationsCache = data;
    _conversationsFetchedAt = DateTime.now();
    return data;
  }

  Future<List<ChatConversationModel>> _fetchConversationsFresh() async {
    try {
      final me = await _currentUserId();
      final rows = await _api.getList(ApiConstants.conversations);
      final conversations = <ChatConversationModel>[];

      for (final raw in rows.whereType<Map<String, dynamic>>()) {
        final id = (raw['id'] ?? '').toString();
        if (id.isEmpty) continue;
        ChatMessageModel? latest;
        try {
          // Best-effort: if last message preview fails, skip it.
          latest = await _latestMessage(id, me);
        } catch (_) {
          latest = null;
        }
        conversations.add(
          ChatConversationModel(
            id: id,
            title: (raw['title'] ?? 'Conversation').toString(),
            isGroup: (raw['type'] ?? 'group').toString() != 'direct',
            participantIds: const [],
            lastMessage: latest,
            unreadCount: raw['unreadCount'] as int? ?? 0,
          ),
        );
      }

      return conversations;
    } catch (e) {
      print('Error fetching conversations: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    final fetchedAt = _messagesFetchedAt[conversationId];
    final cached = _messagesCache[conversationId];
    if (cached != null && fetchedAt != null) {
      final age = DateTime.now().difference(fetchedAt);
      if (age < _messagesTtl) return cached;
    }

    final inFlight = _messagesInFlight[conversationId];
    if (inFlight != null) return inFlight;

    final future = _fetchMessagesFresh(conversationId);
    _messagesInFlight[conversationId] = future;
    final data = await future;
    _messagesInFlight.remove(conversationId);
    _messagesCache[conversationId] = data;
    _messagesFetchedAt[conversationId] = DateTime.now();
    return data;
  }

  Future<List<ChatMessageModel>> _fetchMessagesFresh(
    String conversationId,
  ) async {
    final me = await _currentUserId();
    // Backend returns { messages: [...], hasMore: bool } — NOT a plain array.
    final raw = await _api.get(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: {'limit': 50},
    );
    final rows = (raw['messages'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();

    final messages = rows.map((m) => _mapMessage(m, me)).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final me = await _currentUserId();
    final raw = await _api.post(
      ApiConstants.conversationMessages(conversationId),
      data: {'text': content},
    );
    final sent = _mapMessage(raw, me);

    final existing = _messagesCache[conversationId] ?? const [];
    _messagesCache[conversationId] = [...existing, sent];
    _messagesFetchedAt[conversationId] = DateTime.now();
    _conversationsFetchedAt = null;

    return sent;
  }

  @override
  Future<ChatMessageModel> sendImageMessage(
    String conversationId,
    String imagePath,
  ) async {
    final uploadResponse = await _api.uploadFile(
      ApiConstants.chatUpload,
      imagePath,
      fieldName: 'file',
    );

    final fileId = (uploadResponse['fileId'] ?? '').toString();
    if (fileId.isEmpty) throw Exception('Failed to upload image');

    // Use the Cloudinary CDN URL directly from the upload response.
    // This avoids an extra /files/:id/download redirect and makes
    // Image.network work without auth headers.
    final directUrl = (uploadResponse['url'] ?? '').toString();

    final me = await _currentUserId();
    final raw = await _api.post(
      ApiConstants.conversationMessages(conversationId),
      data: {'mediaFileId': fileId},
    );
    // Merge the direct URL into the raw response so _mapMessage picks it up.
    final enriched = Map<String, dynamic>.from(raw)
      ..['_directMediaUrl'] = directUrl;
    final sent = _mapMessage(enriched, me);

    final existing = _messagesCache[conversationId] ?? const [];
    _messagesCache[conversationId] = [...existing, sent];
    _messagesFetchedAt[conversationId] = DateTime.now();
    _conversationsFetchedAt = null;

    return sent;
  }

  @override
  Future<ChatConversationModel> createConversation({
    required String title,
    required List<String> participantIds,
    required bool isGroup,
  }) async {
    final raw = await _api.post(
      ApiConstants.conversations,
      data: {
        'type': isGroup ? 'group' : 'direct',
        'title': title,
        'memberIds': participantIds,
        'parentVisible': false,
      },
    );

    final id = (raw['id'] ?? '').toString();
    return ChatConversationModel(
      id: id,
      title: (raw['title'] ?? title).toString(),
      isGroup: (raw['type'] ?? 'group').toString() != 'direct',
      participantIds: participantIds,
      lastMessage: null,
      unreadCount: 0,
    );
  }

  @override
  Future<List<MessageReadReceipt>> fetchReadReceipts(String messageId) async {
    final rows = await _api.getList(
      ApiConstants.messageReadReceipts(messageId),
    );
    return rows.whereType<Map<String, dynamic>>().map((raw) {
      final readAt =
          DateTime.tryParse((raw['readAt'] ?? '').toString()) ?? DateTime.now();
      return MessageReadReceipt(
        messageId: (raw['messageId'] ?? messageId).toString(),
        userId: (raw['userId'] ?? '').toString(),
        readAt: readAt,
      );
    }).toList();
  }

  Future<ChatMessageModel?> _latestMessage(
    String conversationId,
    String me,
  ) async {
    // Backend returns { messages: [...], hasMore: bool } — not a plain array.
    final raw = await _api.get(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: {'limit': 1},
    );
    final rows = raw['messages'] as List?;
    final first = rows?.isNotEmpty == true ? rows!.first : null;
    if (first is! Map<String, dynamic>) return null;
    return _mapMessage(first, me);
  }

  ChatMessageModel _mapMessage(Map<String, dynamic> raw, String me) {
    final senderId = (raw['senderId'] ?? '').toString();
    final senderName = (raw['senderName'] ?? '').toString();
    final text = (raw['text'] ?? '').toString();
    final mediaFileId = (raw['mediaFileId'] ?? '').toString();
    final mediaType = (raw['mediaType'] ?? '').toString();
    final mediaName = (raw['mediaName'] ?? '').toString();
    final mediaMimeType = (raw['mediaMimeType'] ?? '').toString();
    final senderProfileImage = (raw['senderProfileImage'] ?? '').toString();
    final senderRole = (raw['senderRole'] ?? '').toString();
    final senderGrade = (raw['senderGrade'] ?? '').toString();
    final createdAt =
        DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
        DateTime.now();
    final type = _resolveMessageType(mediaType);
    // Prefer _directMediaUrl (set when we just uploaded and have the CDN URL
    // immediately), then fall back to constructing from fileBaseUrl + download.
    final directUrl = (raw['_directMediaUrl'] ?? '').toString();
    final mediaUrl = directUrl.isNotEmpty
        ? directUrl
        : mediaFileId.isEmpty
            ? null
            : '${ApiConstants.fileBaseUrl}${ApiConstants.fileDownload(mediaFileId)}';
    return ChatMessageModel(
      id: (raw['id'] ?? '').toString(),
      senderId: senderId,
      senderName: senderId == me
          ? 'You'
          : (senderName.isEmpty ? 'User' : senderName),
      content: text,
      timestamp: createdAt,
      isRead: senderId == me,
      type: type,
      senderProfileImage: senderProfileImage.isEmpty ? null : senderProfileImage,
      senderRole: senderRole.isEmpty ? null : senderRole,
      senderGrade: senderGrade.isEmpty ? null : senderGrade,
      mediaFileId: mediaFileId.isEmpty ? null : mediaFileId,
      mediaUrl: mediaUrl,
      mediaType: mediaType.isEmpty ? null : mediaType,
      mediaName: mediaName.isEmpty ? null : mediaName,
      mediaMimeType: mediaMimeType.isEmpty ? null : mediaMimeType,
      readReceipts: const [],
    );
  }

  MessageType _resolveMessageType(String mediaType) {
    final type = mediaType.toLowerCase();
    if (type == 'image') return MessageType.image;
    if (type == 'video' || type == 'audio' || type == 'file') {
      return MessageType.file;
    }
    return MessageType.text;
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  @override
  Future<List<ChatContactModel>> searchUsers(String query) async {
    try {
      final me = await _currentUserId();
      final myUser = await _storage.getUser();
      final myGrade = (myUser?['grade'] ?? '').toString();
      final mySection = (myUser?['section'] ?? '').toString();
      final normalizedQuery = query.trim().toLowerCase();

      final teachers = await _fetchAssignedTeachers(me, normalizedQuery);
      final students = await _fetchClassmates(
        normalizedQuery,
        me,
        myGrade,
        mySection,
      );

      return [...teachers, ...students];
    } catch (e) {
      return [];
    }
  }

  Future<List<ChatContactModel>> _fetchAssignedTeachers(
    String studentId,
    String query,
  ) async {
    if (studentId.isEmpty) return [];
    final data = await _api.get(ApiConstants.studentTeachers(studentId));
    final teachers = (data['teachers'] as List?) ?? const [];
    return teachers
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final subjects = (json['subjects'] as List?)
                  ?.whereType<String>()
                  .toList() ??
              const <String>[];
          final subjectLabel =
              subjects.isEmpty ? null : subjects.join(', ');
          return ChatContactModel(
            id: (json['id'] ?? '').toString(),
            firstName: (json['firstName'] ?? '').toString(),
            lastName: (json['lastName'] ?? '').toString(),
            role: 'teacher',
            subject: subjectLabel,
          );
        })
        .where((contact) => _matchesQuery(contact, query))
        .toList();
  }

  Future<List<ChatContactModel>> _fetchClassmates(
    String query,
    String me,
    String myGrade,
    String mySection,
  ) async {
    if (myGrade.isEmpty) return [];
    final rows = await _api.getList(
      ApiConstants.usersSearch,
      queryParameters: {'q': query},
    );

    return rows
        .whereType<Map<String, dynamic>>()
        .where((json) {
          final userId = (json['id'] ?? '').toString();
          final role = (json['role'] ?? '').toString().toLowerCase();
          final grade = (json['grade'] ?? '').toString();
          final section = (json['section'] ?? '').toString();

          if (userId == me) return false;
          if (role != 'student') return false;
          if (grade != myGrade) return false;
          if (mySection.isNotEmpty && section != mySection) return false;

          if (query.isEmpty) return true;
          final fullName =
              '${(json['firstName'] ?? '').toString()} ${(json['lastName'] ?? '').toString()}'
                  .trim()
                  .toLowerCase();
          return fullName.contains(query);
        })
        .map((json) => ChatContactModel.fromJson(json))
        .toList();
  }

  bool _matchesQuery(ChatContactModel contact, String query) {
    if (query.isEmpty) return true;
    final name = contact.fullName.toLowerCase();
    final subject = (contact.subject ?? '').toLowerCase();
    return name.contains(query) || subject.contains(query);
  }

  @override
  Future<ConnectionModel> requestConnection(String recipientId) async {
    final data = await _api.post(
      '/connections/request',
      data: {'recipientId': recipientId},
    );
    return ConnectionModel.fromJson(data);
  }

  @override
  Future<ConnectionModel> acceptConnection(String connectionId) async {
    final data = await _api.put('/connections/$connectionId/accept');
    return ConnectionModel.fromJson(data);
  }

  @override
  Future<ConnectionModel> rejectConnection(String connectionId) async {
    final data = await _api.put('/connections/$connectionId/reject');
    return ConnectionModel.fromJson(data);
  }

  @override
  Future<Map<String, List<ConnectionModel>>> fetchConnections() async {
    final data = await _api.get('/connections');
    final sent = (data['sent'] as List?)
            ?.map((json) => ConnectionModel.fromJson(json as Map<String, dynamic>))
            .toList() ??
        [];
    final received = (data['received'] as List?)
            ?.map((json) => ConnectionModel.fromJson(json as Map<String, dynamic>))
            .toList() ??
        [];
    return {'sent': sent, 'received': received};
  }

  @override
  Future<BlockedUserModel> blockUser(String blockedId) async {
    final data = await _api.post(
      '/blocked-users',
      data: {'blockedId': blockedId},
    );
    return BlockedUserModel.fromJson(data);
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    await _api.delete('/blocked-users/$blockedId');
  }

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsers() async {
    final rows = await _api.getList('/blocked-users');
    return rows
        .whereType<Map<String, dynamic>>()
        .map((json) => BlockedUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<InteractionProfileModel> fetchInteractionProfile(String userId) async {
    final data = await _api.get('/users/$userId/interaction-profile');
    return InteractionProfileModel.fromJson(data);
  }
}
