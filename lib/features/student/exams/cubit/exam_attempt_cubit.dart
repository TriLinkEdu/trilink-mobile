import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exam_model.dart';
import '../repositories/student_exams_repository.dart';
import 'exam_attempt_state.dart';

export 'exam_attempt_state.dart';

class ExamAttemptCubit extends Cubit<ExamAttemptState> {
  final StudentExamsRepository _repository;
  String? _lastRequestedExamId;

  ExamAttemptCubit(this._repository) : super(const ExamAttemptState());

  Future<void> loadExam(String? examId) async {
    _lastRequestedExamId = examId;
    emit(state.copyWith(status: ExamAttemptStatus.loading));
    try {
      ExamModel exam;
      if (examId != null) {
        exam = await _repository.fetchExamQuestions(examId);
      } else {
        final exams = await _repository.fetchAvailableExams();
        if (exams.isEmpty) throw Exception('No exams available');
        exam = await _repository.fetchExamQuestions(exams.first.id);
      }
      emit(ExamAttemptState(status: ExamAttemptStatus.loaded, exam: exam));
    } catch (_) {
      emit(state.copyWith(
        status: ExamAttemptStatus.error,
        errorMessage: 'Unable to load exam.',
      ));
    }
  }

  Future<void> retryLoadExam() => loadExam(_lastRequestedExamId);
}
