import '../models/chat_models.dart';

abstract class StudentChatRepository {
  void clearCache() {}

  List<ChatConversationModel>? getCachedConversations();
  List<ChatMessageModel>? getCachedMessages(String conversationId);

  Future<List<ChatConversationModel>> fetchConversations();
  Future<List<ChatMessageModel>> fetchMessages(String conversationId, {String? before, int limit = 50});
  Future<ChatMessageModel> sendMessage(String conversationId, String content);
  Future<ChatMessageModel> sendImageMessage(String conversationId, String imagePath);
  Future<ChatMessageModel> sendFileMessage(String conversationId, String filePath);
  Future<void> markRead(String conversationId, String messageId);
  Future<ChatConversationModel> createConversation({
    required String title,
    required List<String> participantIds,
    required bool isGroup,
  });
  Future<List<ChatMemberModel>> fetchConversationMembers(String conversationId);
  Future<ChatInteractionProfile> fetchInteractionProfile(String userId);
  Future<List<MessageReadReceipt>> fetchReadReceipts(String messageId);
  Future<List<ChatContactModel>> searchUsers(String query);
  
  // Connection management
  Future<ConnectionModel> requestConnection(String recipientId);
  Future<ConnectionModel> acceptConnection(String connectionId);
  Future<ConnectionModel> rejectConnection(String connectionId);
  Future<void> cancelConnection(String connectionId);
  Future<Map<String, List<ConnectionModel>>> fetchConnections();
  
  // Blocking
  Future<BlockedUserModel> blockUser(String blockedId);
  Future<void> unblockUser(String blockedId);
  Future<List<BlockedUserModel>> fetchBlockedUsers();
}
