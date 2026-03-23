class LeaderboardEntry {
  final String studentId;
  final String studentName;
  final int rank;
  final int points;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.rank,
    required this.points,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      rank: json['rank'] as int,
      points: json['points'] as int,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'rank': rank,
        'points': points,
        'avatarUrl': avatarUrl,
      };
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
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
