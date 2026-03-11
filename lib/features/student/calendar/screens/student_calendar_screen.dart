import 'package:flutter/material.dart';

/// School events, exams, and personal schedule.
class StudentCalendarScreen extends StatelessWidget {
  const StudentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(
        child: Text('TODO: Calendar with events, exams, and schedule'),
      ),
    );
  }
}
