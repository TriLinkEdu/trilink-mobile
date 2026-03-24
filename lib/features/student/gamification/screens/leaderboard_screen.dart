import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _weekly = true;

  static const List<_LeaderboardEntry> _weeklyEntries = [
    _LeaderboardEntry(name: 'Alex M.', xp: 4500, isCurrentUser: false),
    _LeaderboardEntry(name: 'Sarah J.', xp: 4320, isCurrentUser: false),
    _LeaderboardEntry(name: 'You', xp: 4100, isCurrentUser: true),
    _LeaderboardEntry(name: 'David R.', xp: 3980, isCurrentUser: false),
  ];

  static const List<_LeaderboardEntry> _monthlyEntries = [
    _LeaderboardEntry(name: 'Sarah J.', xp: 17200, isCurrentUser: false),
    _LeaderboardEntry(name: 'You', xp: 16850, isCurrentUser: true),
    _LeaderboardEntry(name: 'Alex M.', xp: 16420, isCurrentUser: false),
    _LeaderboardEntry(name: 'Marta K.', xp: 16010, isCurrentUser: false),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _weekly ? _weeklyEntries : _monthlyEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _weekly = !_weekly),
            child: Text(_weekly ? 'Weekly' : 'Monthly'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final rank = index + 1;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? Theme.of(context).colorScheme.primary.withAlpha(18)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: entry.isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  child: Text('$rank', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${entry.xp} XP'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardEntry {
  final String name;
  final int xp;
  final bool isCurrentUser;

  const _LeaderboardEntry({
    required this.name,
    required this.xp,
    required this.isCurrentUser,
  });
}
