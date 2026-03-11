import 'package:flutter/material.dart';

class AttendanceSummaryWidget extends StatelessWidget {
  final int totalClasses;
  final int absences;

  const AttendanceSummaryWidget({
    super.key,
    required this.totalClasses,
    required this.absences,
  });

  int get presentCount => totalClasses - absences;
  double get percentage =>
      totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(label: 'Total', value: '$totalClasses'),
            _StatItem(label: 'Present', value: '$presentCount'),
            _StatItem(label: 'Absent', value: '$absences'),
            _StatItem(
              label: 'Rate',
              value: '${percentage.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
