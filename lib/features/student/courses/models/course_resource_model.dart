import '../../../../core/models/curriculum_models.dart';

enum ResourceType { pdf, video, link, document, presentation }

class CourseResourceModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final ResourceType type;
  final DifficultyTier difficulty;
  final String? description;
  final String? url;
  final String? fileSize;
  final String? textbookId;
  final String? textbookFileRecordId;
  final String? textbookCacheKey;
  final DateTime uploadedAt;

  const CourseResourceModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    required this.type,
    this.difficulty = DifficultyTier.medium,
    this.description,
    this.url,
    this.fileSize,
    this.textbookId,
    this.textbookFileRecordId,
    this.textbookCacheKey,
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
      topicId: json['topicId'] as String?,
      type: ResourceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ResourceType.document,
      ),
      difficulty: DifficultyTier.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => DifficultyTier.medium,
      ),
      description: json['description'] as String?,
      url: json['url'] as String?,
      fileSize: json['fileSize'] as String?,
      textbookId: json['textbookId'] as String?,
      textbookFileRecordId: json['textbookFileRecordId'] as String?,
      textbookCacheKey: json['textbookCacheKey'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'topicId': topicId,
    'type': type.name,
    'difficulty': difficulty.name,
    'description': description,
    'url': url,
    'fileSize': fileSize,
    'textbookId': textbookId,
    'textbookFileRecordId': textbookFileRecordId,
    'textbookCacheKey': textbookCacheKey,
    'uploadedAt': uploadedAt.toIso8601String(),
  };
}
