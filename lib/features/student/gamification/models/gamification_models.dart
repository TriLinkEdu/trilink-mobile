enum LeaderboardScope { classScope, school, national }

enum LeaderboardPeriod { weekly, monthly, term }

enum AchievementCategory {
  consistency,
  mastery,
  social,
  exploration,
  milestone,
}

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
  final String? key;
  final String name;
  final String description;
  final String iconUrl;
  final String? iconKey;
  final int xpValue;

  const BadgeModel({
    required this.id,
    this.key,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.iconKey,
    required this.xpValue,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    final iconValue = (json['iconUrl'] ?? json['iconKey'] ?? '').toString();
    return BadgeModel(
      id: json['id'] as String,
      key: json['key'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: iconValue,
      iconKey: json['iconKey'] as String?,
      xpValue: json['xpValue'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'iconKey': iconKey,
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
  final AchievementCategory category;
  final int progressCurrent;
  final int progressTarget;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    this.xpValue = 0,
    required this.isUnlocked,
    this.unlockedAt,
    this.category = AchievementCategory.milestone,
    this.progressCurrent = 0,
    this.progressTarget = 1,
  });

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    int? xpValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    AchievementCategory? category,
    int? progressCurrent,
    int? progressTarget,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      xpValue: xpValue ?? this.xpValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTarget: progressTarget ?? this.progressTarget,
    );
  }

  double get completionRatio {
    if (isUnlocked) return 1;
    if (progressTarget <= 0) return 0;
    return (progressCurrent / progressTarget).clamp(0, 1).toDouble();
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: (json['iconUrl'] ?? '').toString(),
      xpValue: json['xpValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      category: AchievementCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AchievementCategory.milestone,
      ),
      progressCurrent: json['progressCurrent'] as int? ?? 0,
      progressTarget: json['progressTarget'] as int? ?? 1,
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
    'category': category.name,
    'progressCurrent': progressCurrent,
    'progressTarget': progressTarget,
  };
}

class DailyMissionModel {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;
  final int progressCurrent;
  final int progressTarget;

  const DailyMissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isCompleted,
    required this.progressCurrent,
    required this.progressTarget,
  });

  DailyMissionModel copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    bool? isCompleted,
    int? progressCurrent,
    int? progressTarget,
  }) {
    return DailyMissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTarget: progressTarget ?? this.progressTarget,
    );
  }

  double get completionRatio {
    if (isCompleted) return 1;
    if (progressTarget <= 0) return 0;
    return (progressCurrent / progressTarget).clamp(0, 1).toDouble();
  }
}

class TeamChallengeModel {
  final String id;
  final String title;
  final String objective;
  final int progressCurrent;
  final int progressTarget;
  final int contributorCount;
  final DateTime endsAt;

  const TeamChallengeModel({
    required this.id,
    required this.title,
    required this.objective,
    required this.progressCurrent,
    required this.progressTarget,
    required this.contributorCount,
    required this.endsAt,
  });

  double get completionRatio {
    if (progressTarget <= 0) return 0;
    return (progressCurrent / progressTarget).clamp(0, 1).toDouble();
  }
}

class XpProgressModel {
  final int level;
  final int totalXp;
  final int xpIntoCurrentLevel;
  final int xpNeededForNextLevel;
  final int weeklyXpTarget;
  final int weeklyXpEarned;

  const XpProgressModel({
    required this.level,
    required this.totalXp,
    required this.xpIntoCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.weeklyXpTarget,
    required this.weeklyXpEarned,
  });

  double get levelProgressRatio {
    if (xpNeededForNextLevel <= 0) return 0;
    return (xpIntoCurrentLevel / xpNeededForNextLevel).clamp(0, 1).toDouble();
  }

  double get weeklyProgressRatio {
    if (weeklyXpTarget <= 0) return 0;
    return (weeklyXpEarned / weeklyXpTarget).clamp(0, 1).toDouble();
  }
}

class NextBadgeProgressModel {
  final String badgeName;
  final String description;
  final int progressCurrent;
  final int progressTarget;
  final int xpReward;

  const NextBadgeProgressModel({
    required this.badgeName,
    required this.description,
    required this.progressCurrent,
    required this.progressTarget,
    required this.xpReward,
  });

  double get completionRatio {
    if (progressTarget <= 0) return 0;
    return (progressCurrent / progressTarget).clamp(0, 1).toDouble();
  }
}

class GamificationMutationResult {
  final int xpDelta;
  final int newTotalXp;
  final bool leveledUp;
  final int newLevel;
  final List<String> newAchievementIds;
  final List<String> newBadgeIds;
  final int? leaderboardBeforeRank;
  final int? leaderboardAfterRank;

  const GamificationMutationResult({
    required this.xpDelta,
    required this.newTotalXp,
    required this.leveledUp,
    required this.newLevel,
    this.newAchievementIds = const [],
    this.newBadgeIds = const [],
    this.leaderboardBeforeRank,
    this.leaderboardAfterRank,
  });

  static const empty = GamificationMutationResult(
    xpDelta: 0,
    newTotalXp: 0,
    leveledUp: false,
    newLevel: 0,
  );
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
