import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/curriculum_models.dart';
import '../repositories/student_curriculum_repository.dart';

part 'course_list_state.dart';

class CourseListCubit extends Cubit<CourseListState> {
  final StudentCurriculumRepository _repository;

  CourseListCubit(this._repository) : super(const CourseListState());

  Future<void> loadCourses() async {
    emit(state.copyWith(status: CourseListStatus.loading));
    try {
      final subjects = await _repository.fetchSubjects();
      emit(
        CourseListState(status: CourseListStatus.loaded, subjects: subjects),
      );
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
