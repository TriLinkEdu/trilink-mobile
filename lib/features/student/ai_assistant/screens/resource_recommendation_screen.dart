import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';

class ResourceRecommendationScreen extends StatelessWidget {
  final List<ResourceRecommendationModel>? resources;

  const ResourceRecommendationScreen({super.key, this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources != null && resources!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resources')),
        body: _ResourceListPage(resources: resources!),
      );
    }
    return BlocProvider(
      create: (_) => AiAssistantCubit(sl<StudentAiAssistantRepository>())
        ..loadAssistantData(suppressError: true),
      child: const _ResourceRecommendationBlocView(),
    );
  }
}

class _ResourceRecommendationBlocView extends StatelessWidget {
  const _ResourceRecommendationBlocView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: BlocBuilder<AiAssistantCubit, AiAssistantState>(
        builder: (context, state) {
          final loading = state.status == AiAssistantStatus.initial ||
              state.status == AiAssistantStatus.loading;
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = state.data?.resources ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No resources available.'));
          }
          return _ResourceListPage(resources: list);
        },
      ),
    );
  }
}

class _ResourceListPage extends StatefulWidget {
  final List<ResourceRecommendationModel> resources;

  const _ResourceListPage({required this.resources});

  @override
  State<_ResourceListPage> createState() => _ResourceListPageState();
}

class _ResourceListPageState extends State<_ResourceListPage> {
  Future<void> _openResource(ResourceRecommendationModel resource) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened ${resource.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.resources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final resource = widget.resources[index];
        final icon = switch (resource.type.toLowerCase()) {
          'video' => Icons.ondemand_video_rounded,
          'worksheet' => Icons.assignment_rounded,
          'article' => Icons.article_rounded,
          _ => Icons.menu_book_rounded,
        };

        return _ResourceTile(
          title: resource.title,
          subtitle:
              '${resource.type} • ${resource.estimatedTime} • ${resource.level}',
          icon: icon,
          onOpen: () => _openResource(resource),
        );
      },
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onOpen;

  const _ResourceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: onOpen,
          child: const Text('Open'),
        ),
      ),
    );
  }
}
