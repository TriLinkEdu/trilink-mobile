import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
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
      create: (_) =>
          AiAssistantCubit(sl<StudentAiAssistantRepository>(), sl())
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
          final loading =
              state.status == AiAssistantStatus.initial ||
              state.status == AiAssistantStatus.loading;
          if (loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            );
          }
          final list = state.data?.resources ?? [];
          if (list.isEmpty) {
            return const EmptyStateWidget(
              illustration: BooksIllustration(),
              icon: Icons.menu_book_rounded,
              title: 'No resources available',
              subtitle: 'Recommended resources will appear here.',
            );
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
    final urlValue = resource.url;
    if (urlValue == null || urlValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No link is available for this resource yet.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(urlValue);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this resource link.')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this resource right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.resources.length,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
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
        trailing: TextButton(onPressed: onOpen, child: const Text('Open')),
      ),
    );
  }
}
