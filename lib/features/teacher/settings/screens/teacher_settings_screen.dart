import 'package:flutter/material.dart';

/// Teacher settings: account, preferences, notifications, profile customization.
class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          // TODO: Account settings
          // TODO: Preferences
          // TODO: Notification settings
          // TODO: Profile customization
          // TODO: Logout
        ],
      ),
    );
  }
}
