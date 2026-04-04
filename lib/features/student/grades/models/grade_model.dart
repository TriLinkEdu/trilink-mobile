class GradeModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final String assessmentName;
  final double score;
  final double maxScore;
  final DateTime date;
  final String? term;

  const GradeModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.assessmentName,
    required this.score,
    required this.maxScore,
    required this.date,
    this.term,
  });

  double get percentage => (score / maxScore) * 100;

  String get letterGrade {
    final pct = percentage;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      assessmentName: json['assessmentName'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      term: json['term'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'assessmentName': assessmentName,
        'score': score,
        'maxScore': maxScore,
        'date': date.toIso8601String(),
        'term': term,
      };
}
