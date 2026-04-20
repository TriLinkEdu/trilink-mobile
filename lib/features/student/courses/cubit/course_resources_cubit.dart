import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_courses_repository.dart';
import 'course_resources_state.dart';

export 'course_resources_state.dart';

class CourseResourcesCubit extends Cubit<CourseResourcesState> {
  final StudentCoursesRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  CourseResourcesCubit(this._repository) : super(const CourseResourcesState());

  Future<void> loadIfNeeded() async {
    if (state.status == CourseResourcesStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadResources();
  }

  Future<void> loadResources() async {
    emit(state.copyWith(status: CourseResourcesStatus.loading));
    try {
      final resources = await _repository.fetchCourseResources();
      emit(
        CourseResourcesState(
          status: CourseResourcesStatus.loaded,
          resources: resources,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseResourcesStatus.error,
          errorMessage: 'Unable to load resources: $e',
        ),
      );
    }
  }
}
