class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
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
