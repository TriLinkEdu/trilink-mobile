import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_courses_repository.dart';
import 'course_resource_detail_state.dart';

export 'course_resource_detail_state.dart';

class CourseResourceDetailCubit extends Cubit<CourseResourceDetailState> {
  final StudentCoursesRepository _repository;
  final String resourceId;

  CourseResourceDetailCubit(this._repository, this.resourceId)
      : super(const CourseResourceDetailState());

  Future<void> loadResource() async {
    emit(state.copyWith(status: CourseResourceDetailStatus.loading));
    try {
      final all = await _repository.fetchCourseResources();
      final match = all.where((r) => r.id == resourceId);
      if (match.isNotEmpty) {
        emit(CourseResourceDetailState(
          status: CourseResourceDetailStatus.loaded,
          resource: match.first,
        ));
      } else {
        emit(state.copyWith(
          status: CourseResourceDetailStatus.error,
          errorMessage: 'Resource not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CourseResourceDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
