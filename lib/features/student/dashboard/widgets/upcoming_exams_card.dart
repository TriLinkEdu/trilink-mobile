import 'package:flutter/material.dart';

class UpcomingExamsCard extends StatelessWidget {
  const UpcomingExamsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Exams',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: List of upcoming exams
          ],
        ),
      ),
    );
  }
}
