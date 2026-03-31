import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/ai_assistant_cubit.dart';
import 'evaluate_me_screen.dart';
import 'learning_path_screen.dart';
import '../models/ai_assistant_models.dart';
import 'resource_recommendation_screen.dart';
import '../repositories/student_ai_assistant_repository.dart';

/// AI Assistant with Learning Path, Resources, and Evaluate Me tabs.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AiAssistantCubit(sl<StudentAiAssistantRepository>())..loadAssistantData(),
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
  final List<String> _tabs = ['Learning Path', 'Resources', 'Evaluate M...'];

  void _openDetailedPage(int tabIndex) {
    final data = context.read<AiAssistantCubit>().state.data;
    final page = switch (tabIndex) {
      0 => LearningPathScreen(items: data?.learningPath),
      1 => ResourceRecommendationScreen(resources: data?.resources),
      _ => EvaluateMeScreen(insights: data?.insights),
    };

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
      builder: (context, state) {
        final loading = state.status == AiAssistantStatus.initial ||
            state.status == AiAssistantStatus.loading;
        if (loading) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading AI assistant data',
            ),
          );
        }

        if (state.status == AiAssistantStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ??
                        'Unable to load AI assistant content right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<AiAssistantCubit>().loadAssistantData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = state.data;
        if (data == null) {
          return Center(
            child: Text(
              'No AI assistant data available.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }

        return IndexedStack(
          index: _selectedTab,
          children: [
            _LearningPathTab(
              pathItems: data.learningPath,
              onNavigateToPath: () => _openDetailedPage(0),
            ),
            _ResourcesTab(
              resources: data.resources,
              onNavigateToResources: () => _openDetailedPage(1),
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isSelected = _selectedTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
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
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Refresh AI suggestions',
        onPressed: () =>
            context.read<AiAssistantCubit>().loadAssistantData(),
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary, size: 20),
      ),
    );
  }
}

// ─── Learning Path Tab ───────────────────────────────────────────────────────

class _LearningPathTab extends StatefulWidget {
  final List<LearningPathItemModel> pathItems;
  final VoidCallback onNavigateToPath;

  const _LearningPathTab({
    required this.pathItems,
    required this.onNavigateToPath,
  });

  @override
  State<_LearningPathTab> createState() => _LearningPathTabState();
}

class _LearningPathTabState extends State<_LearningPathTab> {
  late List<LearningPathItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.pathItems);
  }

  @override
  void didUpdateWidget(covariant _LearningPathTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathItems != widget.pathItems) {
      _items = List.of(widget.pathItems);
    }
  }

  void _toggleBookmark(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isBookmarked: !_items[index].isBookmarked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Personalized Path',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Curated specifically for you based on your recent quiz results in Physics and Mathematics.',
                        style: TextStyle(
                          fontSize: 12,
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
          const SizedBox(height: 20),

          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No learning path steps available.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              final icon = switch (index % 3) {
                0 => Icons.rocket_launch_rounded,
                1 => Icons.precision_manufacturing_rounded,
                _ => Icons.speed_rounded,
              };

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _items.length - 1 ? 0 : 14,
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
                  onBookmarkToggle: () => _toggleBookmark(index),
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LearningPathScreen(items: _items),
                      ),
                    );
                  },
                ),
              );
            }),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items.isNotEmpty
                            ? "Your current focus is ${_items.first.title}. Continue this step before moving to the next module."
                            : 'Your personalized tips will appear after your next activity.',
                        style: TextStyle(
                          fontSize: 12,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withAlpha(60)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. $title',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subject • $duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
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
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: theme.colorScheme.primary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.play_arrow_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
      return Center(
        child: Text(
          'No study resources available right now.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
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

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resource.type} • ${resource.estimatedTime} • ${resource.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ResourceRecommendationScreen(resources: resources),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
      return Center(
        child: Text(
          'No evaluation insights available right now.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final insight = insights[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 8),
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                insight.summary,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Recommendation: ${insight.recommendation}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: insights.length,
    );
  }
}
