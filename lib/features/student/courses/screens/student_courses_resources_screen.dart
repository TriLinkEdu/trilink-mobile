import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../models/course_resource_model.dart';
import '../repositories/mock_student_courses_repository.dart';
import '../repositories/student_courses_repository.dart';

class StudentCoursesResourcesScreen extends StatefulWidget {
  final StudentCoursesRepository? repository;

  const StudentCoursesResourcesScreen({super.key, this.repository});

  @override
  State<StudentCoursesResourcesScreen> createState() =>
      _StudentCoursesResourcesScreenState();
}

class _StudentCoursesResourcesScreenState
    extends State<StudentCoursesResourcesScreen> {
  late final StudentCoursesRepository _repository =
      widget.repository ?? MockStudentCoursesRepository();
  bool _isLoading = true;
  String? _error;
  List<CourseResourceModel> _resources = const [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resources = await _repository.fetchCourseResources();
      if (!mounted) return;
      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load resources.';
        _isLoading = false;
      });
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Courses & Resources')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadResources,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _resources.isEmpty
                  ? const Center(child: Text('No resources available.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _resources.length,
                      itemBuilder: (context, index) {
                        final resource = _resources[index];
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
  }
}
