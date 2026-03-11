import 'package:flutter/material.dart';

/// Floating button that opens the AI assistant popup.
class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Show AI assistant bottom sheet or navigate to AI screen
        showModalBottomSheet(
          context: context,
          builder: (_) => const _AiAssistantBottomSheet(),
        );
      },
      child: const Icon(Icons.smart_toy),
    );
  }
}

class _AiAssistantBottomSheet extends StatelessWidget {
  const _AiAssistantBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'AI Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Learning Path'),
            onTap: () {
              // TODO: Navigate
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Resource Recommendation'),
            onTap: () {
              // TODO: Navigate
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Evaluate Me'),
            onTap: () {
              // TODO: Navigate
            },
          ),
        ],
      ),
    );
  }
}
