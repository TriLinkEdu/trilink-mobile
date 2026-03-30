import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import '../repositories/mock_student_gamification_repository.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';

/// Gamification hub: streaks, achievements, quick quizzes, leaderboard.
class GamificationScreen extends StatefulWidget {
  final StudentGamificationRepository? repository;

  const GamificationScreen({super.key, this.repository});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  late final StudentGamificationRepository _repository;
  bool _isWeeklyRanking = true;
  bool _isLoading = true;

  StreakModel? _streak;
  List<AchievementModel> _achievements = [];
  List<LeaderboardEntry> _leaderboardEntries = [];
  List<QuizModel> _availableQuizzes = [];

  bool _notifyQuizReminders = true;
  bool _notifyLeaderboard = true;
  bool _notifyAchievements = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentGamificationRepository();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.fetchStreak(),
        _repository.fetchAchievements(),
        _repository.fetchLeaderboard(_isWeeklyRanking ? 'weekly' : 'monthly'),
        _repository.fetchAvailableQuizzes(),
      ]);
      if (!mounted) return;
      setState(() {
        _streak = results[0] as StreakModel;
        _achievements = results[1] as List<AchievementModel>;
        _leaderboardEntries = results[2] as List<LeaderboardEntry>;
        _availableQuizzes = results[3] as List<QuizModel>;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLeaderboardPeriod() async {
    setState(() => _isWeeklyRanking = !_isWeeklyRanking);
    try {
      final entries = await _repository.fetchLeaderboard(
        _isWeeklyRanking ? 'weekly' : 'monthly',
      );
      if (!mounted) return;
      setState(() => _leaderboardEntries = entries);
    } catch (_) {}
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Quiz Reminders'),
                subtitle: const Text('Get reminded about available quizzes'),
                value: _notifyQuizReminders,
                onChanged: (val) {
                  setSheetState(() => _notifyQuizReminders = val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Leaderboard Updates'),
                subtitle: const Text('Know when rankings change'),
                value: _notifyLeaderboard,
                onChanged: (val) {
                  setSheetState(() => _notifyLeaderboard = val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Achievement Notifications'),
                subtitle: const Text('Get notified when you unlock badges'),
                value: _notifyAchievements,
                onChanged: (val) {
                  setSheetState(() => _notifyAchievements = val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showStreakHistory() {
    final streak = _streak;
    if (streak == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Streak History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _streakRow('Current Streak', '${streak.currentStreak} days'),
            const SizedBox(height: 8),
            _streakRow('Longest Streak', '${streak.longestStreak} days'),
            const SizedBox(height: 12),
            const Text(
              'Recent Active Days',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...streak.recentDays.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${d.day}/${d.month}/${d.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _streakRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  IconData _iconForSubject(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('phys') || lower.contains('mechanic')) {
      return Icons.science_rounded;
    }
    if (lower.contains('liter')) return Icons.menu_book_rounded;
    if (lower.contains('hist')) return Icons.public_rounded;
    if (lower.contains('comput')) return Icons.computer_rounded;
    return Icons.quiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.studentDashboard,
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Gamification Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gamification settings',
                    onPressed: _showSettingsSheet,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStreakCard(),
                          const SizedBox(height: 24),
                          _buildAchievementsSection(),
                          const SizedBox(height: 24),
                          _buildQuickQuizSection(),
                          const SizedBox(height: 24),
                          _buildLeaderboardSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _streak;
    return GestureDetector(
      onTap: _showStreakHistory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              streak != null
                  ? '${streak.currentStreak} Day Streak'
                  : '-- Day Streak',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Keep it up! You're on fire.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View History',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final displayAchievements = _achievements.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RouteNames.studentAchievements,
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: displayAchievements.isEmpty
              ? const Center(child: Text('No achievements yet.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayAchievements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final a = displayAchievements[i];
                    final color = a.isUnlocked ? Colors.amber : Colors.grey;
                    final icon = a.isUnlocked
                        ? Icons.emoji_events_rounded
                        : Icons.lock_rounded;
                    return _AchievementChip(
                      icon: icon,
                      label: a.title,
                      sublabel: a.isUnlocked ? 'Unlocked' : 'Locked',
                      color: color,
                      isUnlocked: a.isUnlocked,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickQuizSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Quiz',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableQuizzes.isEmpty)
          const Center(child: Text('No quizzes available.'))
        else
          ...List.generate(_availableQuizzes.length, (i) {
            final quiz = _availableQuizzes[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _availableQuizzes.length - 1 ? 10 : 0,
              ),
              child: _QuickQuizTile(
                icon: _iconForSubject(quiz.subjectName),
                title: '${quiz.subjectName}: ${quiz.title}',
                questions: quiz.questionCount,
                xp: quiz.xpReward,
                onStart: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        subjectId: quiz.subjectId,
                        repository: _repository,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    final topEntries = _leaderboardEntries.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: _toggleLeaderboardPeriod,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeaderboardScreen(
                            repository: _repository,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                  Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isWeeklyRanking ? 'Weekly' : 'Monthly',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (topEntries.isEmpty)
          const Center(child: Text('No leaderboard data.'))
        else
          ...List.generate(topEntries.length, (i) {
            final entry = topEntries[i];
            const rankColors = [
              Color(0xFFFFD700),
              Color(0xFFC0C0C0),
              Color(0xFFCD7F32),
            ];
            const avatarColors = [Colors.orange, Colors.teal, AppColors.primary];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < topEntries.length - 1 ? 8 : 0,
              ),
              child: _LeaderboardRow(
                rank: entry.rank,
                name: entry.studentName,
                classLabel: '',
                xp: '${entry.points} XP',
                avatarColor: avatarColors[i % avatarColors.length],
                rankColor: rankColors[i % rankColors.length],
              ),
            );
          }),
      ],
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isUnlocked;

  const _AchievementChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isUnlocked ? color.withAlpha(25) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? color.withAlpha(80) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? color : Colors.grey.shade400,
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: isUnlocked ? Colors.green : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class _QuickQuizTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int questions;
  final int xp;
  final VoidCallback onStart;

  const _QuickQuizTile({
    required this.icon,
    required this.title,
    required this.questions,
    required this.xp,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$questions Questions  •  $xp XP',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String classLabel;
  final String xp;
  final Color avatarColor;
  final Color rankColor;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.classLabel,
    required this.xp,
    required this.avatarColor,
    required this.rankColor,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withAlpha(15) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withAlpha(50))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor.withAlpha(40),
            child: Icon(Icons.person_rounded, color: avatarColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                if (classLabel.isNotEmpty)
                  Text(
                    classLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            xp,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
