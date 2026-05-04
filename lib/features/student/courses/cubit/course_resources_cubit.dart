import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_courses_repository.dart';
import 'course_resources_state.dart';

export 'course_resources_state.dart';

class CourseResourcesCubit extends Cubit<CourseResourcesState> {
  final StudentCoursesRepository _repository;
  DateTime? _lastLoadedAt;
  String? _lastSubjectId;

  static const Duration _ttl = Duration(seconds: 30);

  CourseResourcesCubit(this._repository) : super(const CourseResourcesState());

  Future<void> loadIfNeeded({String? subjectId}) async {
    final normalized = (subjectId == null || subjectId.isEmpty)
        ? null
        : subjectId;
    if (state.status == CourseResourcesStatus.loaded &&
        _lastSubjectId == normalized &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadResources(subjectId: normalized);
  }

  Future<void> loadResources({String? subjectId}) async {
    emit(state.copyWith(status: CourseResourcesStatus.loading));
    try {
      final resources = subjectId == null || subjectId.isEmpty
          ? await _repository.fetchCourseResources()
          : await _repository.fetchResourcesBySubject(subjectId);
      emit(
        CourseResourcesState(
          status: CourseResourcesStatus.loaded,
          resources: resources,
        ),
      );
      _lastLoadedAt = DateTime.now();
      _lastSubjectId = subjectId;
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
