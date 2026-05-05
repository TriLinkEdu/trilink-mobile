import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../cubit/ai_chat_cubit.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';
import 'ai_chat_screen.dart';

/// AI Assistant with Ask AI, Learning Path, Resources, and Evaluate Me tabs.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AiAssistantCubit(sl<StudentAiAssistantRepository>(), sl())
                ..loadAssistantData(),
        ),
        BlocProvider(
          create: (_) => AiChatCubit(sl<StudentAiAssistantRepository>()),
        ),
      ],
      child: const _AiAssistantView(),
    );
  }
}

class _AiAssistantView extends StatefulWidget {
  const _AiAssistantView();

  @override
  State<_AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<_AiAssistantView> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Ask AI',
    'Learning Path',
    'Resources',
    'Evaluate Me',
  ];

  void _openDetailedPage(int tabIndex) {
    // Ask AI tab (0) has no separate route
    if (tabIndex == 0) return;
    final route = switch (tabIndex) {
      1 => RouteNames.studentLearningPath,
      2 => RouteNames.studentResourceRecommendation,
      _ => RouteNames.studentEvaluateMe,
    };
    Navigator.of(context).pushNamed(route);
  }

  Widget _buildContent() {
    if (_selectedTab == 0) {
      return const AiChatTab();
    }

    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
      builder: (context, state) {
        final loading =
            state.status == AiAssistantStatus.initial ||
            state.status == AiAssistantStatus.loading;
        if (loading) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(),
          );
        }

        if (state.status == AiAssistantStatus.error) {
          return AppErrorWidget(
            message:
                state.errorMessage ??
                'Unable to load AI assistant content right now.',
            onRetry: () => context.read<AiAssistantCubit>().loadAssistantData(),
          );
        }

        final data = state.data;
        if (data == null) {
          return const EmptyStateWidget(
            illustration: BrainIllustration(),
            icon: Icons.psychology_rounded,
            title: 'No AI assistant data',
            subtitle:
                'Your AI learning companion will appear here once set up.',
          );
        }

        // _selectedTab offset: 1=LearningPath, 2=Resources, 3=Evaluate
        return IndexedStack(
          index: _selectedTab - 1,
          children: [
            _LearningPathTab(
              pathItems: data.learningPath,
              onNavigateToPath: () => _openDetailedPage(1),
            ),
            _ResourcesTab(
              resources: data.resources,
              onNavigateToResources: () => _openDetailedPage(2),
            ),
            _EvaluateTab(insights: data.insights),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StudentPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'ai-tutor-hero',
                      child: Material(
                        color: Colors.transparent,
                        child: Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      'AI Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Open detailed page',
                      onPressed: () => _openDetailedPage(_selectedTab),
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close AI Assistant',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,

              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) => AppSpacing.hGapSm,
                  itemBuilder: (context, i) {
                    final isSelected = _selectedTab == i;
                    return Pressable(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'AI tab ${_tabs[i]}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: AppRadius.borderXxl,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.gapSm,

              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTab == 0 ? null : FloatingActionButton.small(
        tooltip: 'Refresh AI suggestions',
        onPressed: () => context.read<AiAssistantCubit>().loadAssistantData(),
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          Icons.auto_awesome,
          color: theme.colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Learning Path Tab ───────────────────────────────────────────────────────

class _LearningPathTab extends StatelessWidget {
  final List<LearningPathItemModel> pathItems;
  final VoidCallback onNavigateToPath;

  const _LearningPathTab({
    required this.pathItems,
    required this.onNavigateToPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = pathItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Personalized Path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapSm,
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Curated specifically for you based on your recent quiz results in Physics and Mathematics.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,

          if (items.isEmpty)
            const EmptyStateWidget(
              illustration: BooksIllustration(),
              icon: Icons.route_rounded,
              title: 'No learning path yet',
              subtitle: 'Your personalized learning steps will appear here.',
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final icon = switch (index % 3) {
                0 => Icons.rocket_launch_rounded,
                1 => Icons.precision_manufacturing_rounded,
                _ => Icons.speed_rounded,
              };

              return StaggeredFadeSlide(
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 14,
                  ),
                  child: _PathItem(
                    index: item.step,
                    icon: icon,
                    title: item.title,
                    subject: item.subject,
                    duration: item.duration,
                    progress: item.progress,
                    isActive: item.isActive,
                    isBookmarked: item.isBookmarked,
                    onBookmarkToggle: () => context
                        .read<AiAssistantCubit>()
                        .toggleLearningPathBookmark(item),
                    onAction: () {
                      Navigator.of(
                        context,
                      ).pushNamed(RouteNames.studentLearningPath);
                    },
                  ),
                ),
              );
            }),
          AppSpacing.gapXl,

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withAlpha(25),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        items.isNotEmpty
                            ? "Your current focus is ${items.first.title}. Continue this step before moving to the next module."
                            : 'Your personalized tips will appear after your next activity.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subject;
  final String duration;
  final double progress;
  final bool isActive;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onAction;

  const _PathItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.isActive,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withAlpha(60)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. $title',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      '$subject • $duration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: onBookmarkToggle,
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ),
          if (isActive) ...[
            AppSpacing.gapMd,
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: theme.colorScheme.primary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            AppSpacing.gapMd,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderXxl,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.hGapXs,
                    Icon(Icons.play_arrow_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ] else ...[
            AppSpacing.gapMd,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderXxl,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Start',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Resources Tab ───────────────────────────────────────────────────────────

class _ResourcesTab extends StatelessWidget {
  final List<ResourceRecommendationModel> resources;
  final VoidCallback onNavigateToResources;

  const _ResourcesTab({
    required this.resources,
    required this.onNavigateToResources,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (resources.isEmpty) {
      return const EmptyStateWidget(
        illustration: BooksIllustration(),
        icon: Icons.menu_book_rounded,
        title: 'No resources yet',
        subtitle: 'Study materials and resources will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final resource = resources[index];
        final icon = switch (resource.type.toLowerCase()) {
          'video' => Icons.ondemand_video_rounded,
          'worksheet' => Icons.assignment_rounded,
          'article' => Icons.article_rounded,
          _ => Icons.menu_book_rounded,
        };

        return StaggeredFadeSlide(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(22),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        '${resource.type} • ${resource.estimatedTime} • ${resource.level}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentResourceRecommendation);
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => AppSpacing.gapMd,
      itemCount: resources.length,
    );
  }
}

// ─── Evaluate Tab ────────────────────────────────────────────────────────────

class _EvaluateTab extends StatelessWidget {
  final List<EvaluateInsightModel> insights;

  const _EvaluateTab({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights.isEmpty) {
      return const EmptyStateWidget(
        illustration: BrainIllustration(),
        icon: Icons.analytics_rounded,
        title: 'No insights yet',
        subtitle:
            'Your evaluation insights will appear here after assessments.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final insight = insights[index];

        return StaggeredFadeSlide(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      insight.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Text(
                  insight.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  'Recommendation: ${insight.recommendation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => AppSpacing.gapMd,
      itemCount: insights.length,
    );
  }
}
