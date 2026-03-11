import 'package:flutter/material.dart';

/// Evaluate submissions and send grades.
class EvaluateSubmissionsScreen extends StatelessWidget {
  final String examId;

  const EvaluateSubmissionsScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluate Submissions')),
      body: const Center(
        child: Text('TODO: Student submissions list with grading'),
      ),
    );
  }
}
