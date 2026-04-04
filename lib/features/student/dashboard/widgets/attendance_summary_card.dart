import 'package:flutter/material.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final double attendancePercent;

  const AttendanceSummaryCard({super.key, this.attendancePercent = 0.87});

  @override
  Widget build(BuildContext context) {
    final double percent = attendancePercent.clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(percent * 100).toStringAsFixed(1)}% present'),
                Text(
                  percent >= 0.9
                      ? 'Excellent'
                      : percent >= 0.8
                          ? 'Good'
                          : 'Needs attention',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
