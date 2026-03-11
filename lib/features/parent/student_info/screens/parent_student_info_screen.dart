import 'package:flutter/material.dart';

/// Detailed results and academic performance of children.
/// Access to student calendar/events.
class ParentStudentInfoScreen extends StatelessWidget {
  const ParentStudentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Information')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Child info header
            // TODO: Academic performance / results
            // TODO: Calendar/events
          ],
        ),
      ),
    );
  }
}
