import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/curriculum_models.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/staggered_animation.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/course_list_cubit.dart';
import '../repositories/student_curriculum_repository.dart';

class StudentCourseDetailScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const StudentCourseDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CourseListCubit(sl<StudentCurriculumRepository>())
            ..loadTopicsIfNeeded(subjectId),
      child: _CourseDetailView(subjectId: subjectId, subjectName: subjectName),
    );
  }
}

class _CourseDetailView extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const _CourseDetailView({required this.subjectId, required this.subjectName});

  static const _subjectColors = <String, Color>{
    'mathematics': AppColors.mathematics,
    'physics': AppColors.physics,
    'literature': AppColors.literature,
    'history': AppColors.history,
    'computer_science': AppColors.computerScience,
  };

  static const _subjectIcons = <String, IconData>{
    'mathematics': Icons.calculate_rounded,
    'physics': Icons.science_rounded,
    'literature': Icons.menu_book_rounded,
    'history': Icons.history_edu_rounded,
    'computer_science': Icons.computer_rounded,
  };

  static const _subjectCodes = <String, String>{
    'mathematics': 'MATH-301',
    'physics': 'PHY-201',
    'literature': 'LIT-101',
    'history': 'HIST-202',
    'computer_science': 'CS-401',
  };

  static const _mockTeachers = <String, String>{
    'mathematics': 'Dr. Abebe Tadesse',
    'physics': 'Prof. Mekdes Alemu',
    'literature': 'Mrs. Hana Bekele',
    'history': 'Mr. Dawit Girma',
    'computer_science': 'Dr. Yonas Kebede',
  };

  Color get _color => _subjectColors[subjectId] ?? AppColors.primary;
  IconData get _icon => _subjectIcons[subjectId] ?? Icons.school_rounded;

  Color _difficultyColor(DifficultyTier tier) {
    switch (tier) {
      case DifficultyTier.easy:
        return AppColors.biology;
      case DifficultyTier.medium:
        return AppColors.warning;
      case DifficultyTier.hard:
        return AppColors.danger;
    }
  }

  String _difficultyLabel(DifficultyTier tier) {
    switch (tier) {
      case DifficultyTier.easy:
        return 'Easy';
      case DifficultyTier.medium:
        return 'Medium';
      case DifficultyTier.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseListCubit, CourseListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(subjectName)),
          body: StudentPageBackground(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CourseListState state) {
    final theme = Theme.of(context);

    if (state.topicsStatus == CourseListStatus.loading ||
        state.topicsStatus == CourseListStatus.initial) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerList(itemCount: 4, itemHeight: 80),
      );
    }

    if (state.topicsStatus == CourseListStatus.error) {
      return AppErrorWidget(
        message: state.errorMessage ?? 'Unable to load course details.',
        onRetry: () => context.read<CourseListCubit>().loadTopics(subjectId),
      );
    }

    if (state.topics.isEmpty) {
      return const EmptyStateWidget(
        illustration: BooksIllustration(),
        icon: Icons.topic_rounded,
        title: 'No topics available',
        subtitle: 'Topics for this course will appear here.',
      );
    }

    return BrandedRefreshIndicator(
      onRefresh: () => context.read<CourseListCubit>().loadTopics(subjectId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: _SubjectHeader(
              subjectName: subjectName,
              code: _subjectCodes[subjectId] ?? '',
              teacher: _mockTeachers[subjectId] ?? 'TBA',
              color: _color,
              icon: _icon,
            ),
          ),
          AppSpacing.gapLg,
          StaggeredFadeSlide(
            index: 1,
            child: Text(
              'Topics',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.gapSm,
          ...List.generate(state.topics.length, (index) {
            final topic = state.topics[index];
            return StaggeredFadeSlide(
              index: index + 2,
              child: _TopicExpansionTile(
                topic: topic,
                color: _color,
                difficultyColor: _difficultyColor,
                difficultyLabel: _difficultyLabel,
              ),
            );
          }),
          AppSpacing.gapXl,
          StaggeredFadeSlide(
            index: state.topics.length + 2,
            child: _ResourcesButton(
              color: _color,
              onTap: () {
                Navigator.of(context).pushNamed(
                  RouteNames.studentCourseResources,
                  arguments: {
                    'subjectId': subjectId,
                    'subjectName': subjectName,
                  },
                );
              },
            ),
          ),
          AppSpacing.gapXl,
        ],
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  final String subjectName;
  final String code;
  final String teacher;
  final Color color;
  final IconData icon;

  const _SubjectHeader({
    required this.subjectName,
    required this.code,
    required this.teacher,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(color: color.withAlpha(40)),
      ),
      color: color.withAlpha(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    code,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.hGapXs,
                      Text(
                        teacher,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicExpansionTile extends StatelessWidget {
  final TopicModel topic;
  final Color color;
  final Color Function(DifficultyTier) difficultyColor;
  final String Function(DifficultyTier) difficultyLabel;

  const _TopicExpansionTile({
    required this.topic,
    required this.color,
    required this.difficultyColor,
    required this.difficultyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dColor = difficultyColor(topic.difficulty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(Icons.topic_rounded, color: color, size: 18),
            ),
            title: Text(
              topic.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: dColor.withAlpha(16),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Text(
                    difficultyLabel(topic.difficulty),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: dColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (topic.subtopics.isNotEmpty) ...[
                  AppSpacing.hGapSm,
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${topic.subtopics.length} subtopic${topic.subtopics.length != 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            children: topic.subtopics.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No subtopics for this topic.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]
                : topic.subtopics.map((sub) {
                    final subColor = difficultyColor(sub.difficulty);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color.withAlpha(120),
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Text(
                              sub.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: subColor.withAlpha(16),
                              borderRadius: AppRadius.borderFull,
                            ),
                            child: Text(
                              difficultyLabel(sub.difficulty),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: subColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ResourcesButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ResourcesButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: color.withAlpha(60)),
        ),
        color: color.withAlpha(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(Icons.folder_open_rounded, color: color, size: 18),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Resources',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'PDFs, videos, links & more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
