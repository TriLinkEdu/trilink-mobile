import 'package:flutter/material.dart';

class AttendanceTrendCard extends StatelessWidget {
  const AttendanceTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: Attendance trend chart
          ],
        ),
      ),
    );
  }
}
