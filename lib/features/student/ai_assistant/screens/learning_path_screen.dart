import 'package:flutter/material.dart';

/// Generate personalized subject learning paths; export as PDF.
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: const Center(
        child: Text('TODO: AI-generated learning path with PDF export'),
      ),
    );
  }
}
