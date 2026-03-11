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
}
