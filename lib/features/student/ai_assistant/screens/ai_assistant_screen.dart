import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/mock_student_ai_assistant_repository.dart';
import '../repositories/student_ai_assistant_repository.dart';

/// AI Assistant with Learning Path, Resources, and Evaluate Me tabs.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Learning Path', 'Resources', 'Evaluate M...'];
  final StudentAiAssistantRepository _repository =
      MockStudentAiAssistantRepository();

  bool _isLoading = true;
  String? _error;
  AiAssistantData? _assistantData;

  @override
  void initState() {
    super.initState();
    _loadAssistantData();
  }

  Future<void> _loadAssistantData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repository.fetchAssistantData();
      if (!mounted) {
        return;
      }
      setState(() {
        _assistantData = data;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load AI assistant content right now.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Loading AI assistant data',
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.textSecondary,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _loadAssistantData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _assistantData;
    if (data == null) {
      return const Center(
        child: Text(
          'No AI assistant data available.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return IndexedStack(
      index: _selectedTab,
      children: [
        _LearningPathTab(pathItems: data.learningPath),
        _ResourcesTab(resources: data.resources),
        _EvaluateTab(insights: data.insights),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  // Logo
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close AI Assistant',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab bar
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
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
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

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Refresh AI suggestions',
        onPressed: () {
          final message = switch (_selectedTab) {
            0 => 'Learning path refreshed for today.',
            1 => 'Top resources selected for your next study session.',
            _ => 'Evaluation tips prepared based on your recent activity.',
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Learning Path Tab ───────────────────────────────────────────────────────

class _LearningPathTab extends StatelessWidget {
  final List<LearningPathItemModel> pathItems;

  const _LearningPathTab({required this.pathItems});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Personalized Path',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Curated specifically for you based on your recent quiz results in Physics and Mathematics.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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

          // Path items
          if (pathItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No learning path steps available.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(pathItems.length, (index) {
              final item = pathItems[index];
              final icon = switch (index % 3) {
                0 => Icons.rocket_launch_rounded,
                1 => Icons.precision_manufacturing_rounded,
                _ => Icons.speed_rounded,
              };

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == pathItems.length - 1 ? 0 : 14,
                ),
                child: _PathItem(
                  index: item.step,
                  icon: icon,
                  title: item.title,
                  subject: item.subject,
                  duration: item.duration,
                  progress: item.progress,
                  isActive: item.isActive,
                ),
              );
            }),
          const SizedBox(height: 20),

          // AI Insight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withAlpha(25),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pathItems.isNotEmpty
                            ? "Your current focus is ${pathItems.first.title}. Continue this step before moving to the next module."
                            : 'Your personalized tips will appear after your next activity.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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

  const _PathItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(60)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. $title',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subject • $duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.bookmark_border_rounded,
                color: Colors.grey.shade400,
                size: 22,
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
                backgroundColor: AppColors.primary.withAlpha(30),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Continuing $title module...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting $title module...')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: Colors.grey.shade300),
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

  const _ResourcesTab({required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const Center(
        child: Text(
          'No study resources available right now.',
          style: TextStyle(color: AppColors.textSecondary),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resource.type} • ${resource.estimatedTime} • ${resource.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${resource.title}...')),
                  );
                },
                child: const Text('Open'),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    if (insights.isEmpty) {
      return const Center(
        child: Text(
          'No evaluation insights available right now.',
          style: TextStyle(color: AppColors.textSecondary),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    insight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Recommendation: ${insight.recommendation}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: insights.length,
    );
  }
}
