import 'package:flutter/material.dart';

class StudentCoursesResourcesScreen extends StatelessWidget {
  const StudentCoursesResourcesScreen({super.key});

  static const List<Map<String, String>> _resources = [
    {
      'course': 'Mathematics',
      'resource': 'Quadratic Equations Notes',
      'type': 'PDF',
    },
    {
      'course': 'Science',
      'resource': 'Cell Structure Slides',
      'type': 'Slides',
    },
    {
      'course': 'English',
      'resource': 'Essay Writing Guide',
      'type': 'Document',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses & Resources')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(resource['resource'] ?? 'Resource'),
              subtitle: Text(resource['course'] ?? 'Course'),
              trailing: Text(resource['type'] ?? 'File'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${resource['resource'] ?? 'Resource'} opened (mock).'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
