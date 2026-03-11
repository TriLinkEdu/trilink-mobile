import 'package:flutter/material.dart';

/// Exams & Assessments hub: create, manage, evaluate.
class TeacherExamsScreen extends StatelessWidget {
  const TeacherExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exams & Assessments')),
      body: const Center(
        child: Text('TODO: Exam list with create/manage options'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create exam
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
