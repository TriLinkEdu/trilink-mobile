import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import 'gamification_state.dart';

export 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final StudentGamificationRepository _repository;

  GamificationCubit(this._repository) : super(const GamificationState());

  Future<void> loadAll() async {
    emit(state.copyWith(status: GamificationStatus.loading));
    try {
      final results = await Future.wait([
        _repository.fetchStreak(),
        _repository.fetchAchievements(),
        _repository.fetchLeaderboard(
          state.isWeeklyRanking ? 'weekly' : 'monthly',
        ),
        _repository.fetchAvailableQuizzes(),
      ]);
      emit(GamificationState(
        status: GamificationStatus.loaded,
        streak: results[0] as StreakModel,
        achievements: results[1] as List<AchievementModel>,
        leaderboardEntries: results[2] as List<LeaderboardEntry>,
        availableQuizzes: results[3] as List<QuizModel>,
        isWeeklyRanking: state.isWeeklyRanking,
      ));
    } catch (_) {
      emit(GamificationState(
        status: GamificationStatus.loaded,
        isWeeklyRanking: state.isWeeklyRanking,
      ));
    }
  }

  Future<void> toggleLeaderboardPeriod() async {
    final next = !state.isWeeklyRanking;
    emit(state.copyWith(isWeeklyRanking: next));
    try {
      final entries = await _repository.fetchLeaderboard(
        next ? 'weekly' : 'monthly',
      );
      emit(state.copyWith(leaderboardEntries: entries));
    } catch (_) {}
  }
}
