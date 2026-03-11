import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  final String subjectId;
  final String? chapterId;

  const QuizScreen({super.key, required this.subjectId, this.chapterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: const Center(child: Text('TODO: Quiz gameplay')),
    );
  }
}
