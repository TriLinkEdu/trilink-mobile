import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/gamification_models.dart';
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
      final result = await _repository.submitQuizAnswers(quizId, answers);
      GamificationMutationResult mutation = const GamificationMutationResult(
        xpDelta: 0,
        newTotalXp: 0,
        leveledUp: false,
        newLevel: 0,
      );
      final subjectId = state.quiz?.subjectId;
      if (subjectId != null) {
        mutation = await _repository.applyQuizOutcome(
          quizId: quizId,
          subjectId: subjectId,
          result: result,
        );
      }

      final allAchievements = await _repository.fetchAchievements();
      final allBadges = await _repository.fetchBadges();
      final newlyUnlockedAchievementTitles = allAchievements
          .where((a) => mutation.newAchievementIds.contains(a.id))
          .map((a) => a.title)
          .toList();
      final newlyUnlockedBadgeNames = allBadges
          .where((b) => mutation.newBadgeIds.contains(b.id))
          .map((b) => b.name)
          .toList();

      emit(
        QuizState(
          status: state.status,
          quiz: state.quiz,
          errorMessage: state.errorMessage,
          submitting: false,
          submitResult: result,
          newlyUnlockedAchievements: newlyUnlockedAchievementTitles,
          newlyUnlockedAchievementIds: mutation.newAchievementIds,
          newlyUnlockedBadges: newlyUnlockedBadgeNames,
          newlyUnlockedBadgeIds: mutation.newBadgeIds,
          leveledUp: mutation.leveledUp,
          newLevel: mutation.newLevel,
          leaderboardDelta:
              mutation.leaderboardBeforeRank != null &&
                  mutation.leaderboardAfterRank != null
              ? mutation.leaderboardBeforeRank! - mutation.leaderboardAfterRank!
              : null,
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
        newlyUnlockedAchievementIds: const [],
        newlyUnlockedBadges: const [],
        newlyUnlockedBadgeIds: const [],
        leveledUp: false,
      ),
    );
  }
}
