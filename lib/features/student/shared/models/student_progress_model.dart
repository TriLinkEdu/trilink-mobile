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
}
