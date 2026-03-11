import 'package:flutter/material.dart';

/// Parent settings: notifications and account preferences.
class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          // TODO: Notification preferences
          // TODO: Account preferences
          // TODO: Logout
        ],
      ),
    );
  }
}
