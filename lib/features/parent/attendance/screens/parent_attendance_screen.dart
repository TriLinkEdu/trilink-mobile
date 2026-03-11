import 'package:flutter/material.dart';

/// View attendance by subject, monitor trends and summary.
class ParentAttendanceScreen extends StatelessWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text('TODO: Child attendance by subject with trends'),
      ),
    );
  }
}
