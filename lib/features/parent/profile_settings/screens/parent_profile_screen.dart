import 'package:flutter/material.dart';

/// Parent profile and settings.
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Personal info
            // TODO: Contact details
          ],
        ),
      ),
    );
  }
}
