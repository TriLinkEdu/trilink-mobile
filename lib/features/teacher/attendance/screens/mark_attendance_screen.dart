import 'package:flutter/material.dart';

/// Mark attendance for a specific class session.
class MarkAttendanceScreen extends StatelessWidget {
  final String classId;
  final String subjectName;

  const MarkAttendanceScreen({
    super.key,
    required this.classId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance: $subjectName')),
      body: const Center(
        child: Text('TODO: Student list with present/absent toggles'),
      ),
    );
  }
}
