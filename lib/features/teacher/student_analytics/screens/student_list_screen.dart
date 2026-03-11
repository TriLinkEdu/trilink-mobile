import 'package:flutter/material.dart';

/// List of students with search and filter capabilities.
class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: const Center(child: Text('TODO: Searchable student list')),
    );
  }
}
