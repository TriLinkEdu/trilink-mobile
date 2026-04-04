import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';

class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => _AiAssistantBottomSheet(parentContext: context),
        );
      },
      child: Hero(
        tag: 'ai-tutor-hero',
        child: Material(
          color: Colors.transparent,
          child: Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _AiAssistantBottomSheet extends StatelessWidget {
  final BuildContext parentContext;
  const _AiAssistantBottomSheet({required this.parentContext});

  void _navigate(BuildContext sheetCtx, String route) {
    Navigator.of(sheetCtx).pop();
    Navigator.of(parentContext).pushNamed(route);
  }

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
            onTap: () => _navigate(context, RouteNames.studentLearningPath),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Resource Recommendation'),
            onTap: () => _navigate(context, RouteNames.studentResourceRecommendation),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Evaluate Me'),
            onTap: () => _navigate(context, RouteNames.studentEvaluateMe),
          ),
        ],
      ),
    );
  }
}
