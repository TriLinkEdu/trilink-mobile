import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Gamification hub: streaks, achievements, quick quizzes, leaderboard.
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
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
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak Card
                    Container(
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
                          const Text(
                            '12 Day Streak',
                            style: TextStyle(
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
                    const SizedBox(height: 24),

                    // Achievements
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
                          onPressed: () {},
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
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _AchievementChip(
                            icon: Icons.school_rounded,
                            label: 'Scholar',
                            sublabel: 'Unlocked',
                            color: Colors.amber,
                            isUnlocked: true,
                          ),
                          SizedBox(width: 14),
                          _AchievementChip(
                            icon: Icons.speed_rounded,
                            label: 'Fast Learner',
                            sublabel: 'Unlocked',
                            color: Colors.green,
                            isUnlocked: true,
                          ),
                          SizedBox(width: 14),
                          _AchievementChip(
                            icon: Icons.calculate_rounded,
                            label: 'Math Whiz',
                            sublabel: 'Locked',
                            color: Colors.grey,
                            isUnlocked: false,
                          ),
                          SizedBox(width: 14),
                          _AchievementChip(
                            icon: Icons.menu_book_rounded,
                            label: 'Bookworm',
                            sublabel: 'Locked',
                            color: Colors.grey,
                            isUnlocked: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Quiz
                    const Text(
                      'Quick Quiz',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _QuickQuizTile(
                      icon: Icons.science_rounded,
                      title: 'Physics: Forces',
                      questions: 5,
                      xp: 100,
                    ),
                    const SizedBox(height: 10),
                    const _QuickQuizTile(
                      icon: Icons.calculate_rounded,
                      title: 'Math: Algebra',
                      questions: 3,
                      xp: 50,
                    ),
                    const SizedBox(height: 24),

                    // Leaderboard
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
                        Row(
                          children: [
                            Icon(
                              Icons.swap_vert_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Weekly',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _LeaderboardRow(
                      rank: 1,
                      name: 'Alex M.',
                      classLabel: 'Class 3A',
                      xp: '4500 XP',
                      avatarColor: Colors.orange,
                      rankColor: Color(0xFFFFD700),
                    ),
                    const SizedBox(height: 8),
                    const _LeaderboardRow(
                      rank: 2,
                      name: 'Sarah J.',
                      classLabel: 'Class 3B',
                      xp: '4320 XP',
                      avatarColor: Colors.teal,
                      rankColor: Color(0xFFC0C0C0),
                    ),
                    const SizedBox(height: 8),
                    const _LeaderboardRow(
                      rank: 3,
                      name: 'You',
                      classLabel: 'Class 3A',
                      xp: '4100 XP',
                      avatarColor: AppColors.primary,
                      rankColor: Color(0xFFCD7F32),
                      isCurrentUser: true,
                    ),
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

  const _QuickQuizTile({
    required this.icon,
    required this.title,
    required this.questions,
    required this.xp,
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
            onPressed: () {},
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
          // Rank badge
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
          // Avatar
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
