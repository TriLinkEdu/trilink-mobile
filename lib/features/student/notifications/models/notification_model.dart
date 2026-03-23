class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? routeName;
  final Map<String, String>? routeArgs;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.routeName,
    this.routeArgs,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? routeName,
    Map<String, String>? routeArgs,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      routeName: routeName ?? this.routeName,
      routeArgs: routeArgs ?? this.routeArgs,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      routeName: json['routeName'] as String?,
      routeArgs: json['routeArgs'] != null
          ? Map<String, String>.from(json['routeArgs'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'routeName': routeName,
        'routeArgs': routeArgs,
      };
}
