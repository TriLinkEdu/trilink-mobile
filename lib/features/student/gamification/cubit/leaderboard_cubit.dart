import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_gamification_repository.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final StudentGamificationRepository _repository;

  LeaderboardCubit(this._repository) : super(const LeaderboardState());

  Future<void> loadLeaderboard() async {
    emit(state.copyWith(status: LeaderboardStatus.loading));
    try {
      final entries = await _repository.fetchLeaderboard(
        state.weekly ? 'weekly' : 'monthly',
      );
      emit(LeaderboardState(
        status: LeaderboardStatus.loaded,
        entries: entries,
        weekly: state.weekly,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: LeaderboardStatus.loaded,
        entries: [],
      ));
    }
  }

  Future<void> togglePeriod() async {
    emit(state.copyWith(weekly: !state.weekly));
    await loadLeaderboard();
  }
}
