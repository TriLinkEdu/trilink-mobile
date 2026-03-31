import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_gamification_repository.dart';
import 'quiz_state.dart';

export 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  final StudentGamificationRepository _repository;

  QuizCubit(this._repository) : super(const QuizState());

  Future<void> loadQuiz(String subjectId) async {
    emit(const QuizState(status: QuizLoadStatus.loading));
    try {
      final quiz = await _repository.fetchQuiz(subjectId);
      emit(QuizState(
        status: QuizLoadStatus.loaded,
        quiz: quiz,
      ));
    } catch (_) {
      emit(const QuizState(
        status: QuizLoadStatus.error,
        errorMessage: 'Could not load quiz. Please try again.',
      ));
    }
  }

  Future<void> submitQuiz(String quizId, Map<String, int> answers) async {
    emit(state.copyWith(submitting: true));
    try {
      final result = await _repository.submitQuizAnswers(quizId, answers);
      emit(QuizState(
        status: state.status,
        quiz: state.quiz,
        errorMessage: state.errorMessage,
        submitting: false,
        submitResult: result,
      ));
    } catch (_) {
      emit(state.copyWith(submitting: false));
      rethrow;
    }
  }

  void clearSubmitResult() {
    emit(QuizState(
      status: state.status,
      quiz: state.quiz,
      errorMessage: state.errorMessage,
      submitting: state.submitting,
    ));
  }
}
