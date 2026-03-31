enum LeaderboardScope { classScope, school, national }

enum LeaderboardPeriod { weekly, monthly, term }

class LeaderboardEntry {
  final String studentId;
  final String studentName;
  final int rank;
  final int points;
  final String? avatarUrl;
  final LeaderboardScope scope;
  final LeaderboardPeriod period;
  final DateTime? calculatedAt;

  const LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.rank,
    required this.points,
    this.avatarUrl,
    this.scope = LeaderboardScope.school,
    this.period = LeaderboardPeriod.weekly,
    this.calculatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      rank: json['rank'] as int,
      points: json['points'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      scope: LeaderboardScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => LeaderboardScope.school,
      ),
      period: LeaderboardPeriod.values.firstWhere(
        (p) => p.name == json['period'],
        orElse: () => LeaderboardPeriod.weekly,
      ),
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'rank': rank,
        'points': points,
        'avatarUrl': avatarUrl,
        'scope': scope.name,
        'period': period.name,
        'calculatedAt': calculatedAt?.toIso8601String(),
      };
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int xpValue;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.xpValue,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      xpValue: json['xpValue'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'xpValue': xpValue,
      };
}

class StudentBadgeModel {
  final String studentId;
  final BadgeModel badge;
  final DateTime awardedAt;

  const StudentBadgeModel({
    required this.studentId,
    required this.badge,
    required this.awardedAt,
  });

  factory StudentBadgeModel.fromJson(Map<String, dynamic> json) {
    return StudentBadgeModel(
      studentId: json['studentId'] as String,
      badge: BadgeModel.fromJson(json['badge'] as Map<String, dynamic>),
      awardedAt: DateTime.parse(json['awardedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'badge': badge.toJson(),
        'awardedAt': awardedAt.toIso8601String(),
      };
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int xpValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    this.xpValue = 0,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      xpValue: json['xpValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'xpValue': xpValue,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };
}

class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> recentDays;

  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.recentDays,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      recentDays: (json['recentDays'] as List)
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'recentDays': recentDays.map((d) => d.toIso8601String()).toList(),
      };
}

class QuizModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final String? chapterId;
  final int questionCount;
  final int xpReward;
  final String difficulty;

  const QuizModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    this.chapterId,
    required this.questionCount,
    required this.xpReward,
    required this.difficulty,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      chapterId: json['chapterId'] as String?,
      questionCount: json['questionCount'] as int,
      xpReward: json['xpReward'] as int,
      difficulty: json['difficulty'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'chapterId': chapterId,
        'questionCount': questionCount,
        'xpReward': xpReward,
        'difficulty': difficulty,
      };
}
