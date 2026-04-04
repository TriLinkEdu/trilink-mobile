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
      emit(QuizState(status: QuizLoadStatus.loaded, quiz: quiz));
    } catch (e) {
      emit(
        const QuizState(
          status: QuizLoadStatus.error,
          errorMessage: 'Could not load quiz. Please try again.',
        ),
      );
      emit(state.copyWith(errorMessage: 'Could not load quiz: $e'));
    }
  }

  Future<void> submitQuiz(String quizId, Map<String, int> answers) async {
    emit(state.copyWith(submitting: true));
    try {
      final beforeAchievements = await _repository.fetchAchievements();
      final beforeXp = await _repository.fetchXpProgress();
      final result = await _repository.submitQuizAnswers(quizId, answers);
      final subjectId = state.quiz?.subjectId;
      if (subjectId != null) {
        await _repository.applyQuizOutcome(
          quizId: quizId,
          subjectId: subjectId,
          result: result,
        );
      }

      final afterAchievements = await _repository.fetchAchievements();
      final afterXp = await _repository.fetchXpProgress();

      final beforeUnlocked = beforeAchievements
          .where((a) => a.isUnlocked)
          .map((a) => a.id)
          .toSet();
      final newlyUnlocked = afterAchievements
          .where((a) => a.isUnlocked && !beforeUnlocked.contains(a.id))
          .map((a) => a.title)
          .toList();

      final leveledUp = afterXp.level > beforeXp.level;

      emit(
        QuizState(
          status: state.status,
          quiz: state.quiz,
          errorMessage: state.errorMessage,
          submitting: false,
          submitResult: result,
          newlyUnlockedAchievements: newlyUnlocked,
          leveledUp: leveledUp,
          newLevel: afterXp.level,
        ),
      );
    } catch (e) {
      emit(state.copyWith(submitting: false));
      emit(state.copyWith(errorMessage: 'Failed to submit quiz: $e'));
      rethrow;
    }
  }

  void clearSubmitResult() {
    emit(
      QuizState(
        status: state.status,
        quiz: state.quiz,
        errorMessage: state.errorMessage,
        submitting: state.submitting,
        newlyUnlockedAchievements: const [],
        leveledUp: false,
      ),
    );
  }
}
