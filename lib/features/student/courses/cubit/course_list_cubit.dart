import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/curriculum_models.dart';
import '../repositories/student_curriculum_repository.dart';

part 'course_list_state.dart';

class CourseListCubit extends Cubit<CourseListState> {
  final StudentCurriculumRepository _repository;
  DateTime? _lastCoursesLoadedAt;
  final Map<String, DateTime> _lastTopicsLoadedAt = <String, DateTime>{};

  static const Duration _ttl = Duration(seconds: 30);

  CourseListCubit(this._repository) : super(const CourseListState());

  Future<void> loadCoursesIfNeeded() async {
    if (state.status == CourseListStatus.loaded &&
        _lastCoursesLoadedAt != null &&
        DateTime.now().difference(_lastCoursesLoadedAt!) < _ttl) {
      return;
    }
    await loadCourses();
  }

  Future<void> loadTopicsIfNeeded(String subjectId) async {
    final last = _lastTopicsLoadedAt[subjectId];
    if (state.topicsStatus == CourseListStatus.loaded &&
        last != null &&
        DateTime.now().difference(last) < _ttl) {
      return;
    }
    await loadTopics(subjectId);
  }

  Future<void> loadCourses() async {
    emit(state.copyWith(status: CourseListStatus.loading));
    try {
      final subjects = await _repository.fetchSubjects();
      emit(
        CourseListState(status: CourseListStatus.loaded, subjects: subjects),
      );
      _lastCoursesLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseListStatus.error,
          errorMessage: 'Unable to load courses: $e',
        ),
      );
    }
  }

  Future<void> loadTopics(String subjectId) async {
    emit(state.copyWith(topicsStatus: CourseListStatus.loading));
    try {
      final topics = await _repository.fetchTopics(subjectId);
      emit(
        state.copyWith(topicsStatus: CourseListStatus.loaded, topics: topics),
      );
      _lastTopicsLoadedAt[subjectId] = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          topicsStatus: CourseListStatus.error,
          errorMessage: 'Unable to load topics: $e',
        ),
      );
    }
  }
}
