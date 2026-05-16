import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/chat_models.dart';
import 'student_chat_repository.dart';

class RealStudentChatRepository implements StudentChatRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static const Duration _conversationsTtl = Duration(seconds: 20);
  static const Duration _messagesTtl = Duration(seconds: 10);

  List<ChatConversationModel>? _conversationsCache;
  DateTime? _conversationsFetchedAt;
  Future<List<ChatConversationModel>>? _conversationsInFlight;

  final Map<String, List<ChatMessageModel>> _messagesCache =
      <String, List<ChatMessageModel>>{};
  final Map<String, DateTime> _messagesFetchedAt = <String, DateTime>{};
  final Map<String, Future<List<ChatMessageModel>>> _messagesInFlight =
      <String, Future<List<ChatMessageModel>>>{};

  void clearCache() {
    _conversationsCache = null;
    _conversationsFetchedAt = null;
    _conversationsInFlight = null;
    _messagesCache.clear();
    _messagesFetchedAt.clear();
    _messagesInFlight.clear();
  }

  @override
  List<ChatConversationModel>? getCachedConversations() => _conversationsCache;

  @override
  List<ChatMessageModel>? getCachedMessages(String conversationId) => 
      _messagesCache[conversationId];

  RealStudentChatRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  // ── Cache keys ─────────────────────────────────────────────

  static String _conversationsCacheKey(String userId) =>
      'chat_conversations_v1_$userId';
  static String _messagesCacheKey(String conversationId) =>
      'chat_messages_v1_$conversationId';

  // ── Conversations ───────────────────────────────────────────

  @override
  Future<List<ChatConversationModel>> fetchConversations() async {
    final userId = await _currentUserId();

    // 1. Restore from disk cache if in-memory is cold.
    if (_conversationsCache == null) {
      _restoreConversationsCache(userId);
    }

    // 2. Return in-memory if fresh enough.
    if (_conversationsCache != null && _conversationsFetchedAt != null) {
      final age = DateTime.now().difference(_conversationsFetchedAt!);
      if (age < _conversationsTtl) return _conversationsCache!;
    }

    // 3. Deduplicate in-flight fetches.
    final inFlight = _conversationsInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchConversationsFresh(userId);
    _conversationsInFlight = future;
    try {
      final data = await future;
      _conversationsCache = data;
      _conversationsFetchedAt = DateTime.now();
      // Persist to disk.
      if (userId.isNotEmpty) {
        await _cacheService.write(
          _conversationsCacheKey(userId),
          data.map((c) => c.toJson()).toList(),
        );
      }
      return data;
    } catch (e) {
      // On network failure, return disk-cached data if available.
      if (e is DioException && _conversationsCache != null) return _conversationsCache!;
      rethrow;
    } finally {
      _conversationsInFlight = null;
    }
  }

  void _restoreConversationsCache(String userId) {
    if (userId.isEmpty) return;
    final entry = _cacheService.read(_conversationsCacheKey(userId), maxAge: _conversationsTtl);
    if (entry == null || entry.data is! List) return;
    try {
      _conversationsCache = (entry.data as List)
          .whereType<Map<String, dynamic>>()
          .map(ChatConversationModel.fromJson)
          .toList();
      _conversationsFetchedAt = entry.savedAt;
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  Future<List<ChatConversationModel>> _fetchConversationsFresh(
    String userId,
  ) async {
    final me = userId.isNotEmpty ? userId : await _currentUserId();
    final rows = await _api.getList(ApiConstants.conversations);
    final conversations = <ChatConversationModel>[];

    for (final raw in rows.whereType<Map<String, dynamic>>()) {
      final id = (raw['id'] ?? '').toString();
      if (id.isEmpty) continue;

      ChatMessageModel? latest;
      final lastText = (raw['lastMessageText'] ?? '').toString();
      final lastAtStr = (raw['lastMessageAt'] ?? '').toString();
      final lastSenderId = (raw['lastMessageSenderId'] ?? '').toString();
      final lastSenderName = (raw['lastMessageSenderName'] ?? '').toString();
      if (lastText.isNotEmpty && lastAtStr.isNotEmpty) {
        final ts = DateTime.tryParse(lastAtStr) ?? DateTime.now();
        latest = ChatMessageModel(
          id: '',
          senderId: lastSenderId,
          senderName: lastSenderId == me ? 'You' : (lastSenderName.isEmpty ? 'User' : lastSenderName),
          content: lastText,
          timestamp: ts,
          isRead: lastSenderId == me,
          type: MessageType.text,
          readReceipts: const [],
        );
      }

      String? avatarPath;
      final isGroup = (raw['type'] ?? 'group').toString() != 'direct';
      if (isGroup) {
        final fileId = raw['avatarFileId']?.toString();
        if (fileId != null && fileId.isNotEmpty) {
          avatarPath = ApiConstants.fileDownload(fileId);
        }
      } else {
        final participants = raw['participants'] as List?;
        if (participants != null) {
          for (final p in participants) {
            if (p is Map<String, dynamic> && p['id'] != me) {
              final fileId = p['profileImageFileId']?.toString();
              if (fileId != null && fileId.isNotEmpty) {
                avatarPath = ApiConstants.fileDownload(fileId);
              }
              break;
            }
          }
        }
      }

      final List<String> pIds = [];
      if (!isGroup) {
        final participants = raw['participants'] as List?;
        if (participants != null) {
          for (final p in participants) {
            if (p is Map<String, dynamic>) {
              final pid = p['id']?.toString();
              if (pid != null && pid.isNotEmpty) {
                pIds.add(pid);
              }
            }
          }
        }
      }

      conversations.add(
        ChatConversationModel(
          id: id,
          title: (raw['title'] ?? 'Conversation').toString(),
          isGroup: isGroup,
          participantIds: pIds,
          lastMessage: latest,
          unreadCount: raw['unreadCount'] as int? ?? 0,
          avatarPath: avatarPath,
        ),
      );
    }

    return conversations;
  }

  // ── Messages ────────────────────────────────────────────────

  @override
  Future<List<ChatMessageModel>> fetchMessages(String conversationId, {String? before, int limit = 50}) async {
    // Bypass memory cache for pagination (cursor-based older-page loads).
    if (before != null && before.isNotEmpty) {
      return _fetchMessagesFresh(conversationId, before: before, limit: limit);
    }
    
    final cached = _messagesCache[conversationId];

    // 1. Restore from disk if in-memory is cold.
    if (cached == null) {
      _restoreMessagesCache(conversationId);
    }

    // 2. Return in-memory if fresh enough.
    final memCached = _messagesCache[conversationId];
    final memFetchedAt = _messagesFetchedAt[conversationId];
    if (memCached != null && memFetchedAt != null) {
      final age = DateTime.now().difference(memFetchedAt);
      if (age < _messagesTtl) return memCached;
    }

    // 3. Deduplicate in-flight.
    final inFlight = _messagesInFlight[conversationId];
    if (inFlight != null) return inFlight;

    final future = _fetchMessagesFresh(conversationId, limit: limit);
    _messagesInFlight[conversationId] = future;
    try {
      final data = await future;
      _messagesCache[conversationId] = data;
      _messagesFetchedAt[conversationId] = DateTime.now();
      // Persist to disk (keep last 100 messages per conversation).
      final toCache = data.length > 100 ? data.sublist(data.length - 100) : data;
      await _cacheService.write(
        _messagesCacheKey(conversationId),
        toCache.map((m) => m.toJson()).toList(),
      );
      return data;
    } catch (e) {
      if (e is DioException && _messagesCache[conversationId] != null) {
        return _messagesCache[conversationId]!;
      }
      rethrow;
    } finally {
      _messagesInFlight.remove(conversationId);
    }
  }

  void _restoreMessagesCache(String conversationId) {
    final entry = _cacheService.read(_messagesCacheKey(conversationId), maxAge: _messagesTtl);
    if (entry == null || entry.data is! List) return;
    try {
      _messagesCache[conversationId] = (entry.data as List)
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList();
      _messagesFetchedAt[conversationId] = entry.savedAt;
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  Future<List<ChatMessageModel>> _fetchMessagesFresh(
    String conversationId, {
    String? before,
    int limit = 50,
  }) async {
    final me = await _currentUserId();
    // Backend returns { messages: [...], hasMore: bool }.
    // Pagination is cursor-based: pass 'before' = oldest message ID already held.
    final params = <String, dynamic>{'limit': limit};
    if (before != null && before.isNotEmpty) params['before'] = before;
    final raw = await _api.get(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: params,
    );
    final rows = (raw['messages'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();

    final messages = rows.map((m) => _mapMessage(m, me)).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // ── Mutations ───────────────────────────────────────────────

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

    // Optimistically update in-memory and disk cache.
    final existing = _messagesCache[conversationId] ?? const [];
    final updated = [...existing, sent];
    _messagesCache[conversationId] = updated;
    _messagesFetchedAt[conversationId] = DateTime.now();
    _conversationsFetchedAt = null; // Invalidate conversation list.

    final toCache = updated.length > 100
        ? updated.sublist(updated.length - 100)
        : updated;
    unawaited(
      _cacheService.write(
        _messagesCacheKey(conversationId),
        toCache.map((m) => m.toJson()).toList(),
      ),
    );

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
    final updated = [...existing, sent];
    _messagesCache[conversationId] = updated;
    _messagesFetchedAt[conversationId] = DateTime.now();
    _conversationsFetchedAt = null;

    final toCache = updated.length > 100
        ? updated.sublist(updated.length - 100)
        : updated;
    unawaited(
      _cacheService.write(
        _messagesCacheKey(conversationId),
        toCache.map((m) => m.toJson()).toList(),
      ),
    );

    return sent;
  }

  @override
  Future<void> markRead(String conversationId, String messageId) async {
    try {
      await _api.post(
        '${ApiConstants.conversations}/$conversationId/messages/$messageId/read',
      );
    } catch (_) {
      // Ignore errors if read receipt fails
    }
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

    // Invalidate conversations cache so the new one shows up.
    _conversationsCache = null;
    _conversationsFetchedAt = null;

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

  // ── Helpers ─────────────────────────────────────────────────

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

  // ── Search / Social ─────────────────────────────────────────

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

  // ── Missing interface methods ──────────────────────────────

  @override
  Future<ChatMessageModel> sendFileMessage(
    String conversationId,
    String filePath,
  ) async {
    // Delegate to image upload path — both send a file via multipart.
    return sendImageMessage(conversationId, filePath);
  }

  @override
  Future<List<ChatMemberModel>> fetchConversationMembers(
    String conversationId,
  ) async {
    try {
      final rows = await _api.getList(
        '${ApiConstants.conversations}/$conversationId/members',
      );
      return rows
          .whereType<Map<String, dynamic>>()
          .map(ChatMemberModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> cancelConnection(String connectionId) async {
    await _api.delete('/connections/$connectionId');
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
  Future<ChatInteractionProfile> fetchInteractionProfile(String userId) async {
    final data = await _api.get('/users/$userId/interaction-profile');
    return ChatInteractionProfile.fromJson(data);
  }
}

// Fire-and-forget helper — avoids unawaited Future warnings.
void unawaited(Future<void> future) {
  future.ignore();
}
