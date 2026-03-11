import 'package:flutter/material.dart';

/// Performance analytics for exams.
class ExamAnalyticsScreen extends StatelessWidget {
  final String examId;

  const ExamAnalyticsScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Analytics')),
      body: const Center(
        child: Text('TODO: Charts and metrics for exam performance'),
      ),
    );
  }
}
