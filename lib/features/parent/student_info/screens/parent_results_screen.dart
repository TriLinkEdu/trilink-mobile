import 'package:flutter/material.dart';

/// Detailed academic results view.
class ParentResultsScreen extends StatelessWidget {
  final String studentId;

  const ParentResultsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Results')),
      body: const Center(child: Text('TODO: Detailed results by subject')),
    );
  }
}
