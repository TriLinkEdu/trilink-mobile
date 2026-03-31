import 'package:flutter/material.dart';

class AssignmentDetailScreen extends StatelessWidget {
  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.title,
    required this.subject,
    required this.dueDateLabel,
    required this.statusLabel,
  });

  final String assignmentId;
  final String title;
  final String subject;
  final String dueDateLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(subject, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(dueDateLabel),
            const SizedBox(height: 4),
            Text('Status: $statusLabel'),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Assignment reference: $assignmentId\n\nThis screen is mock-data based and ready for backend integration.',
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission flow coming next phase.')),
                  );
                },
                child: const Text('Submit Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
