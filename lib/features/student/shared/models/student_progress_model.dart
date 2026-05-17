class StudentProgressModel {
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int level;
  final String levelTitle;

  const StudentProgressModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
  });

  factory StudentProgressModel.fromJson(Map<String, dynamic> json) {
    return StudentProgressModel(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      totalXp: json['totalXp'] as int,
      level: json['level'] as int,
      levelTitle: json['levelTitle'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalXp': totalXp,
        'level': level,
        'levelTitle': levelTitle,
      };
}
