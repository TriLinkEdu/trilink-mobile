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
      emit(
        state.copyWith(
          status: ExamAttemptStatus.loaded,
          exam: exam,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExamAttemptStatus.error,
          errorMessage: 'Unable to load exam.',
        ),
      );
    }
  }

  Future<void> retryLoadExam() => loadExam(_lastRequestedExamId);

  Future<void> startAttempt(String examId, String studentId) async {
    try {
      final attempt = await _repository.startAttempt(examId, studentId);
      emit(state.copyWith(attemptId: attempt.id));
    } catch (e) {
      emit(state.copyWith(submissionErrorMessage: 'Unable to track attempt.'));
    }
  }

  Future<ExamResultModel?> submitCurrentExam(Map<String, int> answers) async {
    final exam = state.exam;
    if (exam == null) return null;

    emit(
      state.copyWith(
        submissionStatus: ExamSubmissionStatus.submitting,
        submissionErrorMessage: null,
      ),
    );

    try {
      final attemptId = state.attemptId;
      if (attemptId == null || attemptId.isEmpty) {
        throw StateError('Exam attempt is not initialized.');
      }

      final attempt = await _repository.submitAttempt(attemptId, answers);
      final score = attempt.score ?? 0;
      final totalQuestions = exam.questions.length;
      final scorePercent = score.clamp(0, 100).toDouble();
      final correct = ((scorePercent / 100) * totalQuestions).round();
      final xp = (scorePercent * 0.5).round();

      final result = ExamResultModel(
        examId: exam.id,
        examTitle: exam.title,
        totalQuestions: totalQuestions,
        correctAnswers: correct,
        score: scorePercent,
        xpEarned: xp,
        answerMap: answers,
      );

      emit(state.copyWith(submissionStatus: ExamSubmissionStatus.success));
      return result;
    } catch (e) {
      emit(
        state.copyWith(
          submissionStatus: ExamSubmissionStatus.error,
          submissionErrorMessage: 'Failed to submit exam.',
        ),
      );
      return null;
    }
  }

  void clearSubmissionStatus() {
    emit(
      state.copyWith(
        submissionStatus: ExamSubmissionStatus.idle,
        submissionErrorMessage: null,
      ),
    );
  }
}
