import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';

class LearningPathScreen extends StatelessWidget {
  final List<LearningPathItemModel>? items;

  const LearningPathScreen({super.key, this.items});

  @override
  Widget build(BuildContext context) {
    if (items != null && items!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Path')),
        body: StudentPageBackground(
          child: _LearningPathContent(initialItems: items!),
        ),
      );
    }
    return BlocProvider(
      create: (_) =>
          AiAssistantCubit(sl<StudentAiAssistantRepository>(), sl())
            ..loadAssistantData(suppressError: true),
      child: const _LearningPathBlocView(),
    );
  }
}

class _LearningPathBlocView extends StatelessWidget {
  const _LearningPathBlocView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: StudentPageBackground(
        child: BlocBuilder<AiAssistantCubit, AiAssistantState>(
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
            final list = state.data?.learningPath ?? [];
            if (list.isEmpty) {
              return const EmptyStateWidget(
                illustration: BooksIllustration(),
                icon: Icons.route_rounded,
                title: 'No learning path items',
                subtitle: 'Your personalized learning path will appear here.',
              );
            }
            return _LearningPathContent(initialItems: list);
          },
        ),
      ),
    );
  }
}

class _LearningPathContent extends StatelessWidget {
  final List<LearningPathItemModel> initialItems;

  const _LearningPathContent({required this.initialItems});

  void _showItemDetail(BuildContext context, LearningPathItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${item.subject}'),
            AppSpacing.gapXs,
            Text('Duration: ${item.duration}'),
            AppSpacing.gapXs,
            Text('Progress: ${(item.progress * 100).toInt()}%'),
            AppSpacing.gapSm,
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (item.progress < 1.0)
            FilledButton(
              onPressed: () async {
                await context.read<AiAssistantCubit>().markLearningPathComplete(
                  item,
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Mark as Complete'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = initialItems;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LearningStepCard(
          title: item.title,
          subtitle: '${item.subject} • ${item.duration}',
          isActive: item.isActive,
          isComplete: item.progress >= 1.0,
          onTap: () => _showItemDetail(context, item),
        );
      },
    );
  }
}

class _LearningStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isComplete;
  final VoidCallback onTap;

  const _LearningStepCard({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      enableHaptic: false,
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            isComplete
                ? Icons.check_circle_rounded
                : isActive
                ? Icons.play_circle_fill_rounded
                : Icons.menu_book_rounded,
            color: isComplete ? AppColors.success : null,
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(
            isComplete
                ? 'Done'
                : isActive
                ? 'Continue'
                : 'Start',
            style: TextStyle(
              color: isComplete
                  ? AppColors.success
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
