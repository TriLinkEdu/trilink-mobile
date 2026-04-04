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

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CourseListCubit(sl<StudentCurriculumRepository>())..loadCourses(),
      child: const _StudentCoursesView(),
    );
  }
}

class _StudentCoursesView extends StatelessWidget {
  const _StudentCoursesView();

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

  static const _mockTeachers = <String, String>{
    'mathematics': 'Dr. Abebe Tadesse',
    'physics': 'Prof. Mekdes Alemu',
    'literature': 'Mrs. Hana Bekele',
    'history': 'Mr. Dawit Girma',
    'computer_science': 'Dr. Yonas Kebede',
  };

  static const _mockTopicCounts = <String, int>{
    'mathematics': 4,
    'physics': 3,
    'literature': 3,
    'history': 4,
    'computer_science': 3,
  };

  static const _mockProgress = <String, double>{
    'mathematics': 0.65,
    'physics': 0.42,
    'literature': 0.78,
    'history': 0.31,
    'computer_science': 0.55,
  };

  Color _colorFor(String subjectId) =>
      _subjectColors[subjectId] ?? AppColors.primary;

  IconData _iconFor(String subjectId) =>
      _subjectIcons[subjectId] ?? Icons.school_rounded;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseListCubit, CourseListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('My Courses')),
          body: StudentPageBackground(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CourseListState state) {
    if (state.status == CourseListStatus.loading ||
        state.status == CourseListStatus.initial) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerList(itemCount: 5, itemHeight: 120),
      );
    }

    if (state.status == CourseListStatus.error) {
      return AppErrorWidget(
        message: state.errorMessage ?? 'Unable to load courses.',
        onRetry: () => context.read<CourseListCubit>().loadCourses(),
      );
    }

    if (state.subjects.isEmpty) {
      return const EmptyStateWidget(
        illustration: BooksIllustration(),
        icon: Icons.school_rounded,
        title: 'No courses enrolled',
        subtitle: 'Your enrolled courses will appear here.',
      );
    }

    return BrandedRefreshIndicator(
      onRefresh: () => context.read<CourseListCubit>().loadCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.subjects.length,
        itemBuilder: (context, index) {
          final subject = state.subjects[index];
          return StaggeredFadeSlide(
            index: index,
            child: _CourseCard(
              subject: subject,
              color: _colorFor(subject.id),
              icon: _iconFor(subject.id),
              teacher: _mockTeachers[subject.id] ?? 'TBA',
              topicCount: _mockTopicCounts[subject.id] ?? 0,
              progress: _mockProgress[subject.id] ?? 0.0,
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final SubjectModel subject;
  final Color color;
  final IconData icon;
  final String teacher;
  final int topicCount;
  final double progress;

  const _CourseCard({
    required this.subject,
    required this.color,
    required this.icon,
    required this.teacher,
    required this.topicCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () {
          Navigator.of(context).pushNamed(
            RouteNames.studentCourseDetail,
            arguments: {'subjectId': subject.id, 'subjectName': subject.name},
          );
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg,
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(80),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(24),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapXxs,
                          Text(
                            subject.code,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        teacher,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(16),
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Text(
                        '$topicCount topics',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.borderFull,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: color.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
