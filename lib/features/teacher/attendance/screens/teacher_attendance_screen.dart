import 'package:flutter/material.dart';

/// Mark attendance per class/subject and view attendance analytics.
class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text('TODO: Class list for marking attendance'),
      ),
    );
  }
}
