import 'package:flutter/material.dart';

/// Screen for selecting role after login (student, teacher, parent).
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose how you use TriLink',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
