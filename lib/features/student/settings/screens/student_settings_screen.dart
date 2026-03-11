import 'package:flutter/material.dart';

/// Personalization options (themes, notifications, privacy).
class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          // TODO: Theme settings
          // TODO: Notification preferences
          // TODO: Privacy settings
          // TODO: Language
          // TODO: Logout
        ],
      ),
    );
  }
}
