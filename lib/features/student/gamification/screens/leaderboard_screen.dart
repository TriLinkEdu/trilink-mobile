import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import '../repositories/mock_student_gamification_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  final StudentGamificationRepository? repository;

  const LeaderboardScreen({super.key, this.repository});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final StudentGamificationRepository _repository;
  bool _weekly = true;
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentGamificationRepository();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _repository.fetchLeaderboard(
        _weekly ? 'weekly' : 'monthly',
      );
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePeriod() {
    setState(() => _weekly = !_weekly);
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          TextButton(
            onPressed: _togglePeriod,
            child: Text(_weekly ? 'Weekly' : 'Monthly'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No leaderboard data available.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerLow,
                            child: Text(
                              '${entry.rank}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text('${entry.points} XP'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
