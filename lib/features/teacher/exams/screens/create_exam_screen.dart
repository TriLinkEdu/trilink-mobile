import 'package:flutter/material.dart';

/// Create quiz/exam with LaTeX support.
class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Exam')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Exam title, subject, duration
            // TODO: Question builder with LaTeX support
            // TODO: Import from exam bank
          ],
        ),
      ),
    );
  }
}
