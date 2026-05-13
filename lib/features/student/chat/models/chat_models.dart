enum MessageType { text, image, file, system }

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaFileId;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;
  final String? mediaMimeType;
  final int? mediaSize;
  final List<MessageReadReceipt> readReceipts;
  
  // Sender profile fields
  final String? senderProfileImage;
  final String? senderRole;
  final String? senderGrade;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
    this.mediaFileId,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
    this.mediaMimeType,
    this.mediaSize,
    this.readReceipts = const [],
    this.senderProfileImage,
    this.senderRole,
    this.senderGrade,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final rawMediaType = (json['mediaType'] as String?)?.toLowerCase();
    MessageType resolvedType = MessageType.text;
    if (rawType != null) {
      resolvedType = MessageType.values.firstWhere(
        (t) => t.name == rawType,
        orElse: () => MessageType.text,
      );
    } else if (rawMediaType != null && rawMediaType.isNotEmpty) {
      if (rawMediaType == 'image') {
        resolvedType = MessageType.image;
      } else {
        resolvedType = MessageType.file;
      }
    }

    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      type: resolvedType,
      mediaFileId: json['mediaFileId'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      mediaName: json['mediaName'] as String?,
      mediaMimeType: json['mediaMimeType'] as String?,
      mediaSize: json['mediaSize'] as int?,
      readReceipts: (json['readReceipts'] as List?)
              ?.map(
                  (r) => MessageReadReceipt.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      senderProfileImage: json['senderProfileImage'] as String?,
      senderRole: json['senderRole'] as String?,
      senderGrade: json['senderGrade'] as String?,
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
        'mediaFileId': mediaFileId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'mediaName': mediaName,
        'mediaMimeType': mediaMimeType,
        'mediaSize': mediaSize,
        'readReceipts': readReceipts.map((r) => r.toJson()).toList(),
        'senderProfileImage': senderProfileImage,
        'senderRole': senderRole,
        'senderGrade': senderGrade,
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
  final String? avatarPath;

  const ChatConversationModel({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    this.avatarPath,
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
      avatarPath: json['avatarPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isGroup': isGroup,
        'participantIds': participantIds,
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'avatarPath': avatarPath,
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
  final String? profileImagePath;

  const ChatContactModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.subject,
    this.grade,
    this.section,
    this.profileImagePath,
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
      profileImagePath: json['profileImagePath'] as String?,
    );
  }
}

class ChatMemberModel {
  final String userId;
  final String role;
  final String firstName;
  final String lastName;
  final String? profileImagePath;

  const ChatMemberModel({
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.profileImagePath,
  });

  String get displayName => '$firstName $lastName'.trim();

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return ChatMemberModel(
      userId: (json['userId'] ?? user['id'] ?? '').toString(),
      role: (json['role'] ?? user['role'] ?? '').toString(),
      firstName: (user['firstName'] ?? '').toString(),
      lastName: (user['lastName'] ?? '').toString(),
      profileImagePath: (user['profileImageFileId'] ?? '').toString(),
    );
  }
}

class ChatInteractionProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? grade;
  final String? section;
  final String? subject;
  final String? department;
  final String? profileImagePath;
  final int totalXp;
  final String connectionStatus;
  final String? connectionId;
  final bool isBlocked;

  const ChatInteractionProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.grade,
    this.section,
    this.subject,
    this.department,
    this.profileImagePath,
    required this.totalXp,
    required this.connectionStatus,
    this.connectionId,
    required this.isBlocked,
  });

  String get displayName => '$firstName $lastName'.trim();

  factory ChatInteractionProfile.fromJson(Map<String, dynamic> json) {
    return ChatInteractionProfile(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      grade: json['grade'] as String?,
      section: json['section'] as String?,
      subject: json['subject'] as String?,
      department: json['department'] as String?,
      profileImagePath: json['profileImageFileId'] as String?,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      connectionStatus: (json['connectionStatus'] ?? 'none').toString(),
      connectionId: json['connectionId'] as String?,
      isBlocked: json['isBlocked'] == true,
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

class InteractionProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? grade;
  final String? profileImageFileId;
  final int totalXp;
  final String connectionStatus;
  final bool isBlocked;

  const InteractionProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.grade,
    this.profileImageFileId,
    required this.totalXp,
    required this.connectionStatus,
    required this.isBlocked,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory InteractionProfileModel.fromJson(Map<String, dynamic> json) {
    return InteractionProfileModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      grade: json['grade'] as String?,
      profileImageFileId: json['profileImageFileId'] as String?,
      totalXp: json['totalXp'] as int? ?? 0,
      connectionStatus: json['connectionStatus'] as String? ?? 'none',
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }
}
