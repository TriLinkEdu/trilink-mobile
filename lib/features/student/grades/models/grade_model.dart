class GradeModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final String assessmentName; // e.g., Quiz 1, Midterm
  final double score;
  final double maxScore;
  final DateTime date;

  const GradeModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.assessmentName,
    required this.score,
    required this.maxScore,
    required this.date,
  });

  double get percentage => (score / maxScore) * 100;

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      assessmentName: json['assessmentName'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
