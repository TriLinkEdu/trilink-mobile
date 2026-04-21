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
    final me = await _currentUserId();
    final rows = await _api.getList(ApiConstants.conversations);
    final conversations = <ChatConversationModel>[];

    for (final raw in rows.whereType<Map<String, dynamic>>()) {
      final id = (raw['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final latest = await _latestMessage(id, me);
      conversations.add(
        ChatConversationModel(
          id: id,
          title: (raw['title'] ?? 'Conversation').toString(),
          isGroup: (raw['type'] ?? 'group').toString() != 'direct',
          participantIds: const [],
          lastMessage: latest,
          unreadCount: 0,
        ),
      );
    }

    return conversations;
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
    final rows = await _api.getList(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: {'limit': 50, 'skip': 0},
    );

    final messages = rows
        .whereType<Map<String, dynamic>>()
        .map((raw) => _mapMessage(raw, me))
        .toList();

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
    final rows = await _api.getList(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: {'limit': 1, 'skip': 0},
    );
    final first = rows.isNotEmpty ? rows.first : null;
    if (first is! Map<String, dynamic>) return null;
    return _mapMessage(first, me);
  }

  ChatMessageModel _mapMessage(Map<String, dynamic> raw, String me) {
    final senderId = (raw['senderId'] ?? '').toString();
    final createdAt =
        DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
        DateTime.now();
    return ChatMessageModel(
      id: (raw['id'] ?? '').toString(),
      senderId: senderId,
      senderName: senderId == me ? 'You' : 'User',
      content: (raw['text'] ?? '').toString(),
      timestamp: createdAt,
      isRead: senderId == me,
      type: MessageType.text,
      readReceipts: const [],
    );
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }
}
