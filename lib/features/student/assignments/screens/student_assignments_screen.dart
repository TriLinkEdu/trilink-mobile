import 'package:flutter/material.dart';

import '../../../../core/routes/route_names.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  static const List<Map<String, String>> _mockAssignments = [
    {
      'id': 'a1',
      'title': 'Algebra Worksheet',
      'subject': 'Mathematics',
      'dueDateLabel': 'Due: Tomorrow',
      'statusLabel': 'Pending',
    },
    {
      'id': 'a2',
      'title': 'Essay Draft',
      'subject': 'English',
      'dueDateLabel': 'Due: Friday',
      'statusLabel': 'In Review',
    },
    {
      'id': 'a3',
      'title': 'Lab Report',
      'subject': 'Science',
      'dueDateLabel': 'Due: Next week',
      'statusLabel': 'Submitted',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockAssignments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final assignment = _mockAssignments[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(
                assignment['title'] ?? 'Assignment',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${assignment['subject'] ?? 'Subject'} • ${assignment['dueDateLabel'] ?? 'Due date'}',
                ),
              ),
              trailing: Text(assignment['statusLabel'] ?? 'Pending'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.studentAssignmentDetail,
                  arguments: {
                    'assignmentId': assignment['id'],
                    'title': assignment['title'],
                    'subject': assignment['subject'],
                    'dueDateLabel': assignment['dueDateLabel'],
                    'statusLabel': assignment['statusLabel'],
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
