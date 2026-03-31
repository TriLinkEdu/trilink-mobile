class StudentGoalModel {
  final String id;
  final String studentId;
  final String goalText;
  final DateTime? targetDate;
  final bool isAchieved;
  final DateTime createdAt;

  const StudentGoalModel({
    required this.id,
    required this.studentId,
    required this.goalText,
    this.targetDate,
    this.isAchieved = false,
    required this.createdAt,
  });

  bool get isOverdue =>
      !isAchieved && targetDate != null && targetDate!.isBefore(DateTime.now());

  int? get daysRemaining {
    if (targetDate == null || isAchieved) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  StudentGoalModel copyWith({
    String? goalText,
    DateTime? targetDate,
    bool? isAchieved,
  }) {
    return StudentGoalModel(
      id: id,
      studentId: studentId,
      goalText: goalText ?? this.goalText,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
      createdAt: createdAt,
    );
  }

  factory StudentGoalModel.fromJson(Map<String, dynamic> json) {
    return StudentGoalModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      goalText: json['goalText'] as String,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      isAchieved: json['isAchieved'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'goalText': goalText,
        'targetDate': targetDate?.toIso8601String(),
        'isAchieved': isAchieved,
        'createdAt': createdAt.toIso8601String(),
      };
}
