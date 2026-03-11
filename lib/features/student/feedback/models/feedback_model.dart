class FeedbackModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
