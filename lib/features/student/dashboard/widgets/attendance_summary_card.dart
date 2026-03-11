import 'package:flutter/material.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: Attendance percentage indicator
          ],
        ),
      ),
    );
  }
}
