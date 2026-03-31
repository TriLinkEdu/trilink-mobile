import 'package:flutter/material.dart';

/// Curated list of PDFs, videos, and other study resources.
class ResourceRecommendationScreen extends StatelessWidget {
  const ResourceRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ResourceTile(
            title: 'Intro to Newtonian Mechanics',
            subtitle: 'Video • 12 min • Core',
            icon: Icons.ondemand_video_rounded,
          ),
          SizedBox(height: 8),
          _ResourceTile(
            title: 'Practice Set: Forces & Motion',
            subtitle: 'Worksheet • 20 min • Practice',
            icon: Icons.assignment_rounded,
          ),
          SizedBox(height: 8),
          _ResourceTile(
            title: 'Exam Tips: Kinematics',
            subtitle: 'Article • 8 min • Revision',
            icon: Icons.article_rounded,
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ResourceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title...')),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}
