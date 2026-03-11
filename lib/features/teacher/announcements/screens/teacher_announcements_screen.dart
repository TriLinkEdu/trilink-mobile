import 'package:flutter/material.dart';

/// Create and send announcements to students or classes.
/// Schedule announcements for exams or events.
class TeacherAnnouncementsScreen extends StatelessWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: const Center(
        child: Text('TODO: Announcements list with create button'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create announcement
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
