import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/curriculum_models.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/subject_visuals.dart';
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
          CourseListCubit(sl<StudentCurriculumRepository>())
            ..loadCoursesIfNeeded(),
      child: const _StudentCoursesView(),
    );
  }
}

class _StudentCoursesView extends StatelessWidget {
  const _StudentCoursesView();

  Color _colorFor(String subjectId) => SubjectVisuals.colorOf(subjectId);

  IconData _iconFor(String subjectId) => SubjectVisuals.iconOf(subjectId);

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
      return EmptyStateWidget(
        illustration: BooksIllustration(),
        icon: Icons.school_rounded,
        title: 'No courses enrolled',
        subtitle: 'Your enrolled courses will appear here.',
        actionLabel: 'Refresh',
        onAction: () => context.read<CourseListCubit>().loadCourses(),
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
              teacher: '', // TODO: Get from enrollment API
              topicCount: 0, // TODO: Get from curriculum API
              progress: 0.0, // TODO: Get from progress API
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
