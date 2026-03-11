import 'package:flutter/material.dart';

/// Submit feedback for a specific subject.
class SubmitFeedbackScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const SubmitFeedbackScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback: $subjectName')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Anonymous feedback form with rating and comments
          ],
        ),
      ),
    );
  }
}
