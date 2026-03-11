class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final String? category; // exam, event, general

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.category,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorName: json['authorName'] as String,
      authorRole: json['authorRole'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String?,
    );
  }
}
