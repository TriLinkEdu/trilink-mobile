import 'package:flutter/material.dart';

class SubjectGradeCard extends StatelessWidget {
  final String subjectName;
  final double averageScore;
  final VoidCallback? onTap;

  const SubjectGradeCard({
    super.key,
    required this.subjectName,
    required this.averageScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(subjectName),
        trailing: Text(
          '${averageScore.toStringAsFixed(1)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: averageScore >= 60 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
