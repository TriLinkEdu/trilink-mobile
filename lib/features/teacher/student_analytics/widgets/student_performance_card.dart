import 'package:flutter/material.dart';

class StudentPerformanceCard extends StatelessWidget {
  final String metricName;
  final String value;
  final IconData icon;

  const StudentPerformanceCard({
    super.key,
    required this.metricName,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metricName, style: const TextStyle(color: Colors.grey)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
