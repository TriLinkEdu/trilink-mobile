import 'package:flutter/material.dart';

/// AI analytics for each student per subject:
/// attendance trends, test/quiz performance, overall learning analytics.
class StudentAnalyticsScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentAnalyticsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(studentName)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Attendance trends chart
            // TODO: Test/quiz performance
            // TODO: Overall learning analytics
          ],
        ),
      ),
    );
  }
}
