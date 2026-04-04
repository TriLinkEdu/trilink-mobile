import 'package:equatable/equatable.dart';
import '../models/course_resource_model.dart';

enum CourseResourceDetailStatus { initial, loading, loaded, error }

class CourseResourceDetailState extends Equatable {
  final CourseResourceDetailStatus status;
  final CourseResourceModel? resource;
  final String? errorMessage;

  const CourseResourceDetailState({
    this.status = CourseResourceDetailStatus.initial,
    this.resource,
    this.errorMessage,
  });

  CourseResourceDetailState copyWith({
    CourseResourceDetailStatus? status,
    CourseResourceModel? resource,
    String? errorMessage,
  }) {
    return CourseResourceDetailState(
      status: status ?? this.status,
      resource: resource ?? this.resource,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, resource, errorMessage];
}
