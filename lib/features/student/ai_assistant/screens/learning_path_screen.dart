import 'package:flutter/material.dart';

/// Generate personalized subject learning paths; export as PDF.
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LearningStepCard(
            title: 'Forces & Motion',
            subtitle: 'Physics • 15 min',
            isActive: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Continuing Forces & Motion...')),
              );
            },
          ),
          const SizedBox(height: 10),
          _LearningStepCard(
            title: "Newton's Laws",
            subtitle: 'Physics • 20 min',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Starting Newton's Laws...")),
              );
            },
          ),
          const SizedBox(height: 10),
          _LearningStepCard(
            title: 'Algebra Revision',
            subtitle: 'Mathematics • 18 min',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Algebra Revision...')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearningStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _LearningStepCard({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isActive ? Icons.play_circle_fill_rounded : Icons.menu_book_rounded,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          isActive ? 'Continue' : 'Start',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
