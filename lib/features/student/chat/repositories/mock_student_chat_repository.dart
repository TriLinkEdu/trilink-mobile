import '../models/chat_models.dart';
import 'student_chat_repository.dart';

class MockStudentChatRepository implements StudentChatRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  int _messageCounter = 100;
  int _conversationCounter = 100;

  @override
  void clearCache() {
    // Mock implementation: no-op since mock data is always in memory
  }

  String _nextMessageId() => 'msg${_messageCounter++}';
  String _nextConversationId() => 'conv${_conversationCounter++}';

  static final List<ChatConversationModel> _conversations = [
    ChatConversationModel(
      id: 'conv1',
      title: 'Physics Study Group',
      isGroup: true,
      participantIds: ['student1', 'student2', 'student3', 'student4'],
      lastMessage: ChatMessageModel(
        id: 'msg1',
        senderId: 'student2',
        senderName: 'Alice Chen',
        content: 'Can someone explain the wave-particle duality concept?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      unreadCount: 3,
    ),
    ChatConversationModel(
      id: 'conv2',
      title: 'Prof. Williams',
      isGroup: false,
      participantIds: ['student1', 'prof1'],
      lastMessage: ChatMessageModel(
        id: 'msg2',
        senderId: 'prof1',
        senderName: 'Prof. Williams',
        content: 'Your essay draft looks good. Minor revisions needed on page 3.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      unreadCount: 0,
    ),
    ChatConversationModel(
      id: 'conv3',
      title: 'Math Homework Help',
      isGroup: true,
      participantIds: ['student1', 'student5', 'student6'],
      lastMessage: ChatMessageModel(
        id: 'msg3',
        senderId: 'student5',
        senderName: 'Bob Martinez',
        content: 'I got 42 for problem 7. Anyone else?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      unreadCount: 0,
    ),
    ChatConversationModel(
      id: 'conv4',
      title: 'Sarah Johnson',
      isGroup: false,
      participantIds: ['student1', 'student7'],
      lastMessage: ChatMessageModel(
        id: 'msg4',
        senderId: 'student7',
        senderName: 'Sarah Johnson',
        content: 'Are you going to the campus event on Friday?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      unreadCount: 1,
    ),
    ChatConversationModel(
      id: 'conv5',
      title: 'Literature Project Team',
      isGroup: true,
      participantIds: ['student1', 'student8', 'student9', 'student10'],
      lastMessage: ChatMessageModel(
        id: 'msg5',
        senderId: 'student8',
        senderName: 'Emily Davis',
        content: 'I\'ve uploaded my section to the shared drive.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
      ),
      unreadCount: 0,
    ),
  ];

  static final Map<String, List<ChatMessageModel>> _messages = {
    'conv1': [
      ChatMessageModel(
        id: 'msg1a',
        senderId: 'student3',
        senderName: 'Carlos Rivera',
        content: 'Hey everyone, ready for the physics quiz next week?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg1b',
        senderId: 'student1',
        senderName: 'You',
        content: 'I think so. Still struggling with electromagnetic induction though.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg1c',
        senderId: 'student4',
        senderName: 'Diana Park',
        content: 'I found a great video explaining Faraday\'s law. Let me share.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg1d',
        senderId: 'student2',
        senderName: 'Alice Chen',
        content: 'Can someone explain the wave-particle duality concept?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
    ],
    'conv2': [
      ChatMessageModel(
        id: 'msg2a',
        senderId: 'student1',
        senderName: 'You',
        content: 'Professor, I\'ve submitted my essay draft for review.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg2b',
        senderId: 'prof1',
        senderName: 'Prof. Williams',
        content: 'Thank you. I\'ll review it this afternoon.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg2c',
        senderId: 'prof1',
        senderName: 'Prof. Williams',
        content: 'Your essay draft looks good. Minor revisions needed on page 3.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ],
    'conv3': [
      ChatMessageModel(
        id: 'msg3a',
        senderId: 'student1',
        senderName: 'You',
        content: 'Anyone started the calculus homework yet?',
        timestamp: DateTime.now().subtract(const Duration(hours: 7)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg3b',
        senderId: 'student6',
        senderName: 'Fatima Al-Rashid',
        content: 'Yes! Problem 5 is tricky. You need to use integration by parts twice.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg3c',
        senderId: 'student5',
        senderName: 'Bob Martinez',
        content: 'I got 42 for problem 7. Anyone else?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
    ],
    'conv4': [
      ChatMessageModel(
        id: 'msg4a',
        senderId: 'student1',
        senderName: 'You',
        content: 'Hey Sarah, how was the literature lecture today?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg4b',
        senderId: 'student7',
        senderName: 'Sarah Johnson',
        content: 'It was great! We discussed post-modernism.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg4c',
        senderId: 'student7',
        senderName: 'Sarah Johnson',
        content: 'Are you going to the campus event on Friday?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
    ],
    'conv5': [
      ChatMessageModel(
        id: 'msg5a',
        senderId: 'student9',
        senderName: 'James Lee',
        content: 'Team, let\'s divide the remaining sections evenly.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg5b',
        senderId: 'student1',
        senderName: 'You',
        content: 'I\'ll take the conclusion and bibliography.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg5c',
        senderId: 'student10',
        senderName: 'Grace Kim',
        content: 'I\'ll handle the character analysis section.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'msg5d',
        senderId: 'student8',
        senderName: 'Emily Davis',
        content: 'I\'ve uploaded my section to the shared drive.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
      ),
    ],
  };

  @override
  Future<List<ChatConversationModel>> fetchConversations() async {
    await Future<void>.delayed(_latency);
    return List<ChatConversationModel>.from(_conversations);
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    String? before,
    int limit = 50,
  }) async {
    await Future<void>.delayed(_latency);
    final messages = List<ChatMessageModel>.from(_messages[conversationId] ?? []);
    if (before == null || before.isEmpty) {
      return messages.length <= limit ? messages : messages.sublist(messages.length - limit);
    }
    final idx = messages.indexWhere((m) => m.id == before);
    if (idx <= 0) return [];
    final start = (idx - limit).clamp(0, idx);
    return messages.sublist(start, idx);
  }

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    await Future<void>.delayed(_latency);
    final message = ChatMessageModel(
      id: _nextMessageId(),
      senderId: 'student1',
      senderName: 'You',
      content: content,
      timestamp: DateTime.now(),
      isRead: true,
    );
    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      final reply = ChatMessageModel(
        id: _nextMessageId(),
        senderId: 'bot',
        senderName: 'Auto Reply',
        content: 'Thanks for your message! I\'ll get back to you shortly.',
        timestamp: DateTime.now(),
        isRead: false,
      );
      _messages[conversationId]!.add(reply);
    });

    return message;
  }

  @override
  Future<ChatMessageModel> sendImageMessage(
    String conversationId,
    String imagePath,
  ) async {
    await Future<void>.delayed(_latency);
    final message = ChatMessageModel(
      id: _nextMessageId(),
      senderId: 'student1',
      senderName: 'You',
      content: '[Image]',
      timestamp: DateTime.now(),
      isRead: true,
      type: MessageType.image,
    );
    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    return message;
  }

  @override
  Future<ChatMessageModel> sendFileMessage(
    String conversationId,
    String filePath,
  ) async {
    await Future<void>.delayed(_latency);
    final message = ChatMessageModel(
      id: _nextMessageId(),
      senderId: 'student1',
      senderName: 'You',
      content: '[File]',
      timestamp: DateTime.now(),
      isRead: true,
      type: MessageType.file,
    );
    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    return message;
  }

  @override
  Future<ChatConversationModel> createConversation({
    required String title,
    required List<String> participantIds,
    required bool isGroup,
  }) async {
    await Future<void>.delayed(_latency);
    final conversation = ChatConversationModel(
      id: _nextConversationId(),
      title: title,
      isGroup: isGroup,
      participantIds: participantIds,
    );
    _conversations.add(conversation);
    _messages[conversation.id] = [];
    return conversation;
  }

  @override
  Future<List<MessageReadReceipt>> fetchReadReceipts(String messageId) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return [
      MessageReadReceipt(
        messageId: messageId,
        userId: 'user_8f2a1c3e',
        readAt: now.subtract(const Duration(minutes: 47, seconds: 12)),
      ),
      MessageReadReceipt(
        messageId: messageId,
        userId: 'student_4b91d702',
        readAt: now.subtract(const Duration(minutes: 32, seconds: 8)),
      ),
      MessageReadReceipt(
        messageId: messageId,
        userId: 'prof_2e7c9a01',
        readAt: now.subtract(const Duration(minutes: 5, seconds: 41)),
      ),
    ];
  }

  @override
  Future<List<ChatMemberModel>> fetchConversationMembers(
    String conversationId,
  ) async {
    await Future<void>.delayed(_latency);
    return const [];
  }

  @override
  Future<List<ChatContactModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const ChatContactModel(
        id: 'teacher1',
        firstName: 'Dr. Abebe',
        lastName: 'Tadesse',
        role: 'teacher',
        subject: 'Mathematics',
      ),
      const ChatContactModel(
        id: 'student2',
        firstName: 'Alice',
        lastName: 'Chen',
        role: 'student',
        grade: '9',
      ),
    ];
  }

  @override
  Future<ConnectionModel> requestConnection(String recipientId) async {
    throw UnimplementedError();
  }

  @override
  Future<ConnectionModel> acceptConnection(String connectionId) async {
    throw UnimplementedError();
  }

  @override
  Future<ConnectionModel> rejectConnection(String connectionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelConnection(String connectionId) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<Map<String, List<ConnectionModel>>> fetchConnections() async {
    return {'sent': [], 'received': []};
  }

  @override
  Future<BlockedUserModel> blockUser(String blockedId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> unblockUser(String blockedId) async {}

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsers() async {
    return [];
  }

  @override
  Future<ChatInteractionProfile> fetchInteractionProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ChatInteractionProfile(
      id: userId,
      firstName: 'Mock',
      lastName: 'User',
      role: 'student',
      grade: '10',
      section: 'A',
      totalXp: 1500,
      connectionStatus: 'none',
      connectionId: null,
      isBlocked: false,
    );
  }
}
