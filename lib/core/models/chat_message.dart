// ─── Chat Message Model ───────────────────────────────────────────────────────
// Matches the EnrichedMessage shape returned by the backend chat API.

class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({required this.emoji, required this.userIds});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        emoji: json['emoji'] as String? ?? '',
        userIds: (json['userIds'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {'emoji': emoji, 'userIds': userIds};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageReaction &&
          emoji == other.emoji &&
          _listEquals(userIds, other.userIds);

  @override
  int get hashCode => Object.hash(emoji, Object.hashAll(userIds));
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarFileId;
  final String text;
  final String createdAt;
  final String updatedAt;
  final String? replyToId;
  final Map<String, dynamic>? replyTo; // {id, senderId, senderName, text}
  final String? mediaFileId;
  final String? mediaType; // 'image' | 'video' | 'file' | 'audio'
  final String? mediaName;
  final String? mediaMimeType;
  final int? mediaSize;
  final List<MessageReaction> reactions;
  final bool isDeleted;
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = '',
    this.senderAvatarFileId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.replyToId,
    this.replyTo,
    this.mediaFileId,
    this.mediaType,
    this.mediaName,
    this.mediaMimeType,
    this.mediaSize,
    this.reactions = const [],
    this.isDeleted = false,
    this.isEdited = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse reactions — backend returns { emoji: [userId, ...] } map OR list
    List<MessageReaction> reactions = [];
    final rawReactions = json['reactions'];
    if (rawReactions is Map) {
      reactions = rawReactions.entries
          .map((e) => MessageReaction(
                emoji: e.key as String,
                userIds: (e.value as List<dynamic>? ?? []).cast<String>(),
              ))
          .toList();
    } else if (rawReactions is List) {
      reactions = rawReactions
          .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    // Parse replyTo preview
    Map<String, dynamic>? replyTo;
    final rawReplyTo = json['replyTo'];
    if (rawReplyTo is Map<String, dynamic>) {
      replyTo = rawReplyTo;
    }

    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderAvatarFileId: json['senderAvatarFileId'] as String?,
      text: json['text'] as String? ?? json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['createdAt'] as String? ?? '',
      replyToId: json['replyToId'] as String?,
      replyTo: replyTo,
      mediaFileId: json['mediaFileId'] as String?,
      mediaType: json['mediaType'] as String?,
      mediaName: json['mediaName'] as String?,
      mediaMimeType: json['mediaMimeType'] as String?,
      mediaSize: json['mediaSize'] as int?,
      reactions: reactions,
      isDeleted: json['deletedAt'] != null || (json['isDeleted'] as bool? ?? false),
      isEdited: json['editedAt'] != null || (json['isEdited'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarFileId': senderAvatarFileId,
        'text': text,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'replyToId': replyToId,
        'replyTo': replyTo,
        'mediaFileId': mediaFileId,
        'mediaType': mediaType,
        'mediaName': mediaName,
        'mediaMimeType': mediaMimeType,
        'mediaSize': mediaSize,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'isDeleted': isDeleted,
        'isEdited': isEdited,
      };

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarFileId,
    String? text,
    String? createdAt,
    String? updatedAt,
    String? replyToId,
    Map<String, dynamic>? replyTo,
    String? mediaFileId,
    String? mediaType,
    String? mediaName,
    String? mediaMimeType,
    int? mediaSize,
    List<MessageReaction>? reactions,
    bool? isDeleted,
    bool? isEdited,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatarFileId: senderAvatarFileId ?? this.senderAvatarFileId,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        replyToId: replyToId ?? this.replyToId,
        replyTo: replyTo ?? this.replyTo,
        mediaFileId: mediaFileId ?? this.mediaFileId,
        mediaType: mediaType ?? this.mediaType,
        mediaName: mediaName ?? this.mediaName,
        mediaMimeType: mediaMimeType ?? this.mediaMimeType,
        mediaSize: mediaSize ?? this.mediaSize,
        reactions: reactions ?? this.reactions,
        isDeleted: isDeleted ?? this.isDeleted,
        isEdited: isEdited ?? this.isEdited,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          senderAvatarFileId == other.senderAvatarFileId &&
          text == other.text &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          replyToId == other.replyToId &&
          mediaFileId == other.mediaFileId &&
          mediaType == other.mediaType &&
          mediaName == other.mediaName &&
          mediaMimeType == other.mediaMimeType &&
          mediaSize == other.mediaSize &&
          _listEquals(reactions, other.reactions) &&
          isDeleted == other.isDeleted &&
          isEdited == other.isEdited;

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatarFileId,
        text,
        createdAt,
        updatedAt,
        replyToId,
        mediaFileId,
        mediaType,
        mediaName,
        mediaMimeType,
        mediaSize,
        Object.hashAll(reactions),
        isDeleted,
        isEdited,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
