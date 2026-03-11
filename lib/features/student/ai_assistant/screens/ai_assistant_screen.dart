import 'package:flutter/material.dart';

/// AI Assistant popup with Learning Path, Resource Recommendation, Evaluate Me.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AiFeatureCard(
            icon: Icons.route,
            title: 'Learning Path',
            description:
                'Generate personalized subject learning paths. Export as PDF.',
            onTap: () {
              // TODO: Navigate to learning path
            },
          ),
          _AiFeatureCard(
            icon: Icons.menu_book,
            title: 'Resource Recommendation',
            description: 'Curated PDFs, videos, and study resources.',
            onTap: () {
              // TODO: Navigate to resources
            },
          ),
          _AiFeatureCard(
            icon: Icons.analytics,
            title: 'Evaluate Me',
            description:
                'AI-generated feedback about your performance and learning habits.',
            onTap: () {
              // TODO: Navigate to evaluate
            },
          ),
        ],
      ),
    );
  }
}

class _AiFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AiFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
