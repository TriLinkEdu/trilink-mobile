class PerformanceReportModel {
  final String id;
  final String studentId;
  final double overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final DateTime generatedAt;

  const PerformanceReportModel({
    required this.id,
    required this.studentId,
    required this.overallScore,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.generatedAt,
  });

  String get scoreLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Very Good';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }

  factory PerformanceReportModel.fromJson(Map<String, dynamic> json) {
    return PerformanceReportModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      overallScore: (json['overallScore'] as num).toDouble(),
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'overallScore': overallScore,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'recommendations': recommendations,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
