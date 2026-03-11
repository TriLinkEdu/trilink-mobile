import 'package:flutter/material.dart';

/// Personalized notifications (academic, administrative, marketing).
/// Supports mark as read/unread.
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Text('TODO: Notifications list with read/unread'),
      ),
    );
  }
}
