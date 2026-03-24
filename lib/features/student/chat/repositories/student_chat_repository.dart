import '../models/chat_models.dart';

abstract class StudentChatRepository {
  Future<List<ChatConversationModel>> fetchConversations();
  Future<List<ChatMessageModel>> fetchMessages(String conversationId);
  Future<ChatMessageModel> sendMessage(String conversationId, String content);
  Future<ChatConversationModel> createConversation({
    required String title,
    required List<String> participantIds,
    required bool isGroup,
  });
}
