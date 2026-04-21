import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_courses_repository.dart';
import 'course_resource_detail_state.dart';

export 'course_resource_detail_state.dart';

class CourseResourceDetailCubit extends Cubit<CourseResourceDetailState> {
  final StudentCoursesRepository _repository;
  final String resourceId;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  CourseResourceDetailCubit(this._repository, this.resourceId)
    : super(const CourseResourceDetailState());

  Future<void> loadIfNeeded() async {
    if (state.status == CourseResourceDetailStatus.loaded &&
        state.resource?.id == resourceId &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadResource();
  }

  Future<void> loadResource() async {
    emit(state.copyWith(status: CourseResourceDetailStatus.loading));
    try {
      final resource = await _repository.fetchResourceById(resourceId);
      if (resource != null) {
        emit(
          CourseResourceDetailState(
            status: CourseResourceDetailStatus.loaded,
            resource: resource,
          ),
        );
        _lastLoadedAt = DateTime.now();
      } else {
        emit(
          state.copyWith(
            status: CourseResourceDetailStatus.error,
            errorMessage: 'Resource not found',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseResourceDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
