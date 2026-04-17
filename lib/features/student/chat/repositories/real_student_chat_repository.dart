import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/chat_models.dart';
import 'student_chat_repository.dart';

class RealStudentChatRepository implements StudentChatRepository {
  final ApiClient _api;
  final StorageService _storage;

  RealStudentChatRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<List<ChatConversationModel>> fetchConversations() async {
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
    return _mapMessage(raw, me);
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
    return const [];
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
