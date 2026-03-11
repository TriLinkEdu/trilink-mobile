import 'package:flutter/material.dart';

/// Teacher calendar: schedule classes, exams, events.
class TeacherCalendarScreen extends StatelessWidget {
  const TeacherCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(
        child: Text('TODO: Calendar with class, exam, event scheduling'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new event
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
