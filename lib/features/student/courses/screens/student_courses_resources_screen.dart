import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/course_resources_cubit.dart';
import '../models/course_resource_model.dart';
import '../repositories/student_courses_repository.dart';

class StudentCoursesResourcesScreen extends StatelessWidget {
  const StudentCoursesResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CourseResourcesCubit(sl<StudentCoursesRepository>())..loadResources(),
      child: const _StudentCoursesResourcesView(),
    );
  }
}

class _StudentCoursesResourcesView extends StatelessWidget {
  const _StudentCoursesResourcesView();

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
        return Colors.red;
      case ResourceType.video:
        return Colors.purple;
      case ResourceType.link:
        return Colors.blue;
      case ResourceType.document:
        return Colors.teal;
      case ResourceType.presentation:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseResourcesCubit, CourseResourcesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Courses & Resources')),
          body: state.status == CourseResourcesStatus.loading ||
                  state.status == CourseResourcesStatus.initial
              ? const Center(child: CircularProgressIndicator())
              : state.status == CourseResourcesStatus.error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.errorMessage ?? '',
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => context
                                .read<CourseResourcesCubit>()
                                .loadResources(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state.resources.isEmpty
                      ? const Center(child: Text('No resources available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.resources.length,
                          itemBuilder: (context, index) {
                            final resource = state.resources[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _colorForType(resource.type).withAlpha(30),
                                  child: Icon(
                                    _iconForType(resource.type),
                                    color: _colorForType(resource.type),
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  resource.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(resource.subjectName),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _colorForType(resource.type)
                                        .withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    resource.typeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _colorForType(resource.type),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    RouteNames.studentCourseResourceDetail,
                                    arguments: {'resourceId': resource.id},
                                  );
                                },
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }
}
