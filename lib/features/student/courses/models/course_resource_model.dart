enum ResourceType { pdf, video, link, document, presentation }

class CourseResourceModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final ResourceType type;
  final String? description;
  final String? url;
  final String? fileSize;
  final DateTime uploadedAt;

  const CourseResourceModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.type,
    this.description,
    this.url,
    this.fileSize,
    required this.uploadedAt,
  });

  String get typeLabel {
    switch (type) {
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.video:
        return 'Video';
      case ResourceType.link:
        return 'Link';
      case ResourceType.document:
        return 'Document';
      case ResourceType.presentation:
        return 'Presentation';
    }
  }

  factory CourseResourceModel.fromJson(Map<String, dynamic> json) {
    return CourseResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      type: ResourceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ResourceType.document,
      ),
      description: json['description'] as String?,
      url: json['url'] as String?,
      fileSize: json['fileSize'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'type': type.name,
        'description': description,
        'url': url,
        'fileSize': fileSize,
        'uploadedAt': uploadedAt.toIso8601String(),
      };
}
