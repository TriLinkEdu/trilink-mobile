class TopicMasteryModel {
  final String studentId;
  final String topicId;
  final String topicName;
  final String subjectId;
  final double masteryLevel;
  final DateTime lastAssessed;

  const TopicMasteryModel({
    required this.studentId,
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.masteryLevel,
    required this.lastAssessed,
  });

  bool get isMastered => masteryLevel >= 0.8;
  bool get needsWork => masteryLevel < 0.5;

  String get masteryLabel {
    if (masteryLevel >= 0.8) return 'Mastered';
    if (masteryLevel >= 0.6) return 'Proficient';
    if (masteryLevel >= 0.4) return 'Developing';
    return 'Needs Work';
  }

  factory TopicMasteryModel.fromJson(Map<String, dynamic> json) {
    return TopicMasteryModel(
      studentId: json['studentId'] as String,
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      subjectId: json['subjectId'] as String,
      masteryLevel: (json['masteryLevel'] as num).toDouble(),
      lastAssessed: DateTime.parse(json['lastAssessed'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'topicId': topicId,
        'topicName': topicName,
        'subjectId': subjectId,
        'masteryLevel': masteryLevel,
        'lastAssessed': lastAssessed.toIso8601String(),
      };
}
