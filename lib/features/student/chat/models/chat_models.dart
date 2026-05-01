enum MessageType { text, image, file, system }

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final List<MessageReadReceipt> readReceipts;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
    this.readReceipts = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      readReceipts: (json['readReceipts'] as List?)
              ?.map(
                  (r) => MessageReadReceipt.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type.name,
        'readReceipts': readReceipts.map((r) => r.toJson()).toList(),
      };
}

class MessageReadReceipt {
  final String messageId;
  final String userId;
  final DateTime readAt;

  const MessageReadReceipt({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'userId': userId,
        'readAt': readAt.toIso8601String(),
      };
}

class ChatConversationModel {
  final String id;
  final String title;
  final bool isGroup;
  final List<String> participantIds;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  const ChatConversationModel({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isGroup: json['isGroup'] as bool,
      participantIds: List<String>.from(json['participantIds']),
      lastMessage: json['lastMessage'] != null
          ? ChatMessageModel.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isGroup': isGroup,
        'participantIds': participantIds,
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
      };
}

class ChatContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? subject;
  final String? grade;
  final String? section;

  const ChatContactModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.subject,
    this.grade,
    this.section,
  });

  String get fullName => '$firstName $lastName'.trim();
  
  String get displayName {
    if (role == 'teacher' && subject != null && subject!.isNotEmpty) {
      return '$fullName ($subject)';
    }
    return fullName;
  }

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      subject: json['subject'] as String?,
      grade: json['grade'] as String?,
      section: json['section'] as String?,
    );
  }
}

enum ConnectionStatus { pending, accepted, rejected }

class ConnectionModel {
  final String id;
  final String requesterId;
  final String recipientId;
  final ConnectionStatus status;
  final DateTime createdAt;
  final String? requesterName;
  final String? recipientName;

  const ConnectionModel({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.recipientName,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      recipientId: json['recipientId'] as String,
      status: ConnectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ConnectionStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      requesterName: json['requesterName'] as String?,
      recipientName: json['recipientName'] as String?,
    );
  }
}

class BlockedUserModel {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
  final String? blockedName;

  const BlockedUserModel({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
    this.blockedName,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] as String,
      blockerId: json['blockerId'] as String,
      blockedId: json['blockedId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      blockedName: json['blockedName'] as String?,
    );
  }
}
