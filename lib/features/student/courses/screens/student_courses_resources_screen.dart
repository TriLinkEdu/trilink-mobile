import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/course_resources_cubit.dart';
import '../models/course_resource_model.dart';
import '../repositories/student_courses_repository.dart';

class StudentCoursesResourcesScreen extends StatelessWidget {
  final String? subjectId;
  final String? subjectName;

  const StudentCoursesResourcesScreen({
    super.key,
    this.subjectId,
    this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CourseResourcesCubit(sl<StudentCoursesRepository>())
            ..loadIfNeeded(subjectId: subjectId),
      child: _StudentCoursesResourcesView(subjectName: subjectName),
    );
  }
}

class _StudentCoursesResourcesView extends StatelessWidget {
  final String? subjectName;

  const _StudentCoursesResourcesView({this.subjectName});

  IconData _iconForType(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf_rounded;
      case ResourceType.video:
        return Icons.play_circle_rounded;
      case ResourceType.link:
        return Icons.link_rounded;
      case ResourceType.document:
        return Icons.description_rounded;
      case ResourceType.presentation:
        return Icons.slideshow_rounded;
    }
  }

  Color _colorForType(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return AppColors.danger;
      case ResourceType.video:
        return AppColors.levelPurple;
      case ResourceType.link:
        return AppColors.info;
      case ResourceType.document:
        return AppColors.computerScience;
      case ResourceType.presentation:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseResourcesCubit, CourseResourcesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              subjectName == null || subjectName!.isEmpty
                  ? 'Course Resources'
                  : '$subjectName Resources',
            ),
          ),
          body: StudentPageBackground(
            child:
                state.status == CourseResourcesStatus.loading ||
                    state.status == CourseResourcesStatus.initial
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(),
                  )
                : state.status == CourseResourcesStatus.error
                ? AppErrorWidget(
                    message: state.errorMessage ?? 'Unable to load resources.',
                    onRetry: () =>
                        context.read<CourseResourcesCubit>().loadResources(),
                  )
                : state.resources.isEmpty
                ? const EmptyStateWidget(
                    illustration: BooksIllustration(),
                    icon: Icons.folder_open_rounded,
                    title: 'No resources available',
                    subtitle: 'Course resources will appear here when added.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.resources.length,
                    itemBuilder: (context, index) {
                      final resource = state.resources[index];
                      void openResource() {
                        Navigator.of(context).pushNamed(
                          RouteNames.studentCourseResourceDetail,
                          arguments: {'resourceId': resource.id},
                        );
                      }

                      return StaggeredFadeSlide(
                        index: index,
                        child: Pressable(
                          onTap: openResource,
                          enableHaptic: false,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: openResource,
                              leading: CircleAvatar(
                                backgroundColor: _colorForType(
                                  resource.type,
                                ).withAlpha(30),
                                child: Icon(
                                  _iconForType(resource.type),
                                  color: _colorForType(resource.type),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                resource.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(resource.subjectName),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorForType(
                                    resource.type,
                                  ).withAlpha(20),
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Text(
                                  resource.typeLabel,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _colorForType(resource.type),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
