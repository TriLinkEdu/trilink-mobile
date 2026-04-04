import 'package:equatable/equatable.dart';
import '../models/course_resource_model.dart';

enum CourseResourcesStatus { initial, loading, loaded, error }

class CourseResourcesState extends Equatable {
  final CourseResourcesStatus status;
  final List<CourseResourceModel> resources;
  final String? errorMessage;

  const CourseResourcesState({
    this.status = CourseResourcesStatus.initial,
    this.resources = const [],
    this.errorMessage,
  });

  CourseResourcesState copyWith({
    CourseResourcesStatus? status,
    List<CourseResourceModel>? resources,
    String? errorMessage,
  }) {
    return CourseResourcesState(
      status: status ?? this.status,
      resources: resources ?? this.resources,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, resources, errorMessage];
}
