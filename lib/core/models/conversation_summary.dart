// ─── Conversation Summary Model ───────────────────────────────────────────────
// Matches the EnrichedConversation shape returned by GET /conversations.

class ConversationMember {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? profileImageFileId;

  const ConversationMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileImageFileId,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    // Members can be nested under a 'user' key (from the members endpoint)
    // or flat (from the conversations list)
    final user = json['user'] as Map<String, dynamic>?;
    final src = user ?? json;
    return ConversationMember(
      id: src['id'] as String? ?? json['userId'] as String? ?? '',
      firstName: src['firstName'] as String? ?? '',
      lastName: src['lastName'] as String? ?? '',
      role: src['role'] as String? ?? json['role'] as String? ?? 'member',
      profileImageFileId: src['profileImageFileId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'profileImageFileId': profileImageFileId,
      };

  ConversationMember copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? role,
    String? profileImageFileId,
  }) =>
      ConversationMember(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role ?? this.role,
        profileImageFileId: profileImageFileId ?? this.profileImageFileId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationMember &&
          id == other.id &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          role == other.role &&
          profileImageFileId == other.profileImageFileId;

  @override
  int get hashCode =>
      Object.hash(id, firstName, lastName, role, profileImageFileId);
}

class ConversationSummary {
  final String id;
  final String type; // 'direct' | 'group'
  final String title;
  final String? description;
  final String? avatarFileId;
  final int unreadCount;
  final String? lastMessageText;
  final String? lastMessageAt;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final List<ConversationMember> members;
  final List<ConversationMember> participants; // for direct conversations
  final String? classOfferingId;
  final bool parentVisible;
  final String createdAt;
  final String updatedAt;

  const ConversationSummary({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.avatarFileId,
    this.unreadCount = 0,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.members = const [],
    this.participants = const [],
    this.classOfferingId,
    this.parentVisible = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    List<ConversationMember> parseMembers(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((m) => ConversationMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return ConversationSummary(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'direct',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageAt: json['lastMessageAt'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      members: parseMembers(json['members']),
      participants: parseMembers(json['participants']),
      classOfferingId: json['classOfferingId'] as String?,
      parentVisible: json['parentVisible'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'avatarFileId': avatarFileId,
        'unreadCount': unreadCount,
        'lastMessageText': lastMessageText,
        'lastMessageAt': lastMessageAt,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageSenderName': lastMessageSenderName,
        'members': members.map((m) => m.toJson()).toList(),
        'participants': participants.map((m) => m.toJson()).toList(),
        'classOfferingId': classOfferingId,
        'parentVisible': parentVisible,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  ConversationSummary copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? avatarFileId,
    int? unreadCount,
    String? lastMessageText,
    String? lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    List<ConversationMember>? members,
    List<ConversationMember>? participants,
    String? classOfferingId,
    bool? parentVisible,
    String? createdAt,
    String? updatedAt,
  }) =>
      ConversationSummary(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        avatarFileId: avatarFileId ?? this.avatarFileId,
        unreadCount: unreadCount ?? this.unreadCount,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        lastMessageSenderName:
            lastMessageSenderName ?? this.lastMessageSenderName,
        members: members ?? this.members,
        participants: participants ?? this.participants,
        classOfferingId: classOfferingId ?? this.classOfferingId,
        parentVisible: parentVisible ?? this.parentVisible,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSummary &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          description == other.description &&
          avatarFileId == other.avatarFileId &&
          unreadCount == other.unreadCount &&
          lastMessageText == other.lastMessageText &&
          lastMessageAt == other.lastMessageAt &&
          lastMessageSenderId == other.lastMessageSenderId &&
          lastMessageSenderName == other.lastMessageSenderName &&
          _listEquals(members, other.members) &&
          _listEquals(participants, other.participants) &&
          classOfferingId == other.classOfferingId &&
          parentVisible == other.parentVisible &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        title,
        description,
        avatarFileId,
        unreadCount,
        lastMessageText,
        lastMessageAt,
        lastMessageSenderId,
        lastMessageSenderName,
        Object.hashAll(members),
        Object.hashAll(participants),
        classOfferingId,
        parentVisible,
        createdAt,
        updatedAt,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
