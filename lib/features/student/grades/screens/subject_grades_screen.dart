import 'package:flutter/material.dart';

/// Shows tests/quizzes and scores for a specific subject.
class SubjectGradesScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const SubjectGradesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: const Center(
        child: Text('TODO: Tests, quizzes, scores and progress charts'),
      ),
    );
  }
}
