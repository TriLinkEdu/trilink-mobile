import 'package:flutter/material.dart';

/// Manage notifications to students and classes.
class TeacherNotificationsScreen extends StatelessWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Text('TODO: Manage notifications sent to students'),
      ),
    );
  }
}
