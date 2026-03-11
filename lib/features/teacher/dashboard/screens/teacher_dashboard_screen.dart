import 'package:flutter/material.dart';

/// Teacher dashboard: overview of class performance, attendance trends, notifications.
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Class performance overview
            // TODO: Attendance trends
            // TODO: Recent notifications
          ],
        ),
      ),
    );
  }
}
