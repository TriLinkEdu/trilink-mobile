import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import '../repositories/mock_student_gamification_repository.dart';

class AchievementsListScreen extends StatefulWidget {
  final StudentGamificationRepository? repository;
  const AchievementsListScreen({super.key, this.repository});

  @override
  State<AchievementsListScreen> createState() => _AchievementsListScreenState();
}

class _AchievementsListScreenState extends State<AchievementsListScreen> {
  late final StudentGamificationRepository _repo;
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockStudentGamificationRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _achievements = await _repo.fetchAchievements();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = _achievements.where((a) => a.isUnlocked).toList();
    final locked = _achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unlocked.isNotEmpty) ...[
                  Text('Unlocked (${unlocked.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...unlocked.map((a) => _AchievementTile(achievement: a)),
                  const SizedBox(height: 24),
                ],
                if (locked.isNotEmpty) ...[
                  Text('Locked (${locked.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...locked.map((a) => _AchievementTile(achievement: a)),
                ],
              ],
            ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked
                ? Colors.amber.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUnlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
            color: isUnlocked ? Colors.amber : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: isUnlocked ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle_rounded, color: Colors.green)
            : null,
      ),
    );
  }
}
