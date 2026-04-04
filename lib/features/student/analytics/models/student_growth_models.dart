class StudentWeeklySnapshot {
  final double attendanceRate;
  final double averageQuizScore;
  final int dueAssignments;
  final String trend;
  final List<String> focusSubjects;
  final String summary;

  const StudentWeeklySnapshot({
    required this.attendanceRate,
    required this.averageQuizScore,
    required this.dueAssignments,
    required this.trend,
    required this.focusSubjects,
    required this.summary,
  });
}

class StudentTrendPoint {
  final String label;
  final double value;

  const StudentTrendPoint({required this.label, required this.value});
}

class StudentSubjectTrend {
  final String subjectId;
  final String subjectName;
  final List<StudentTrendPoint> points;
  final List<String> strengthTopics;
  final List<String> riskTopics;
  final String recommendation;

  const StudentSubjectTrend({
    required this.subjectId,
    required this.subjectName,
    required this.points,
    required this.strengthTopics,
    required this.riskTopics,
    required this.recommendation,
  });
}

class StudentPerformanceTrends {
  final int examReadinessScore;
  final List<StudentSubjectTrend> subjects;

  const StudentPerformanceTrends({
    required this.examReadinessScore,
    required this.subjects,
  });
}

class StudentAttendanceInsight {
  final double currentRate;
  final List<StudentTrendPoint> weeklyTrend;
  final String riskLevel;
  final double projectedMonthEndRate;
  final String bestDay;
  final String weakDay;

  const StudentAttendanceInsight({
    required this.currentRate,
    required this.weeklyTrend,
    required this.riskLevel,
    required this.projectedMonthEndRate,
    required this.bestDay,
    required this.weakDay,
  });
}

class StudentActionItem {
  final String id;
  final String title;
  final String reason;
  final String category;
  final int effortMinutes;
  final String? routeName;
  final Map<String, dynamic>? routeArgs;
  final bool done;

  const StudentActionItem({
    required this.id,
    required this.title,
    required this.reason,
    required this.category,
    required this.effortMinutes,
    required this.routeName,
    required this.routeArgs,
    required this.done,
  });

  StudentActionItem copyWith({
    String? id,
    String? title,
    String? reason,
    String? category,
    int? effortMinutes,
    String? routeName,
    Map<String, dynamic>? routeArgs,
    bool? done,
  }) {
    return StudentActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      effortMinutes: effortMinutes ?? this.effortMinutes,
      routeName: routeName ?? this.routeName,
      routeArgs: routeArgs ?? this.routeArgs,
      done: done ?? this.done,
    );
  }
}
