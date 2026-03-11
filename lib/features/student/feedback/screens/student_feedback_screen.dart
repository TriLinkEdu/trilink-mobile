import 'package:flutter/material.dart';

/// Anonymous feedback for each subject/teacher.
class StudentFeedbackScreen extends StatelessWidget {
  const StudentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: const Center(
        child: Text('TODO: Subject/teacher feedback form (anonymous)'),
      ),
    );
  }
}
