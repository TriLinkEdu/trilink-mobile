import 'package:flutter/material.dart';

/// Gamification hub: leaderboards, achievements, streaks, quizzes.
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Games & Achievements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Leaderboard'),
              Tab(text: 'Quizzes'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('TODO: Leaderboard')),
            Center(child: Text('TODO: Subject & chapter quizzes')),
            Center(child: Text('TODO: Achievements & streaks')),
          ],
        ),
      ),
    );
  }
}
