import 'package:flutter/material.dart';

/// AI-generated general feedback about performance and learning habits.
class EvaluateMeScreen extends StatelessWidget {
  const EvaluateMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluate Me')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InsightCard(
            title: 'Strength',
            summary: 'You consistently perform well in conceptual questions.',
            recommendation: 'Keep using quick concept summaries before practice.',
          ),
          SizedBox(height: 10),
          _InsightCard(
            title: 'Focus Area',
            summary: 'Multi-step numerical questions reduce your speed.',
            recommendation: 'Practice 3 timed multi-step problems daily.',
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String summary;
  final String recommendation;

  const _InsightCard({
    required this.title,
    required this.summary,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(summary),
            const SizedBox(height: 8),
            Text('Recommendation: $recommendation'),
          ],
        ),
      ),
    );
  }
}
