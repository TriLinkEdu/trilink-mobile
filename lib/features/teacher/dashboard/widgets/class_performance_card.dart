import 'package:flutter/material.dart';

class ClassPerformanceCard extends StatelessWidget {
  const ClassPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: Performance chart/metrics
          ],
        ),
      ),
    );
  }
}
