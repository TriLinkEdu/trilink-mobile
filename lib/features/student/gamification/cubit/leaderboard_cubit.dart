import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_gamification_repository.dart';
import 'leaderboard_state.dart';

export 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final StudentGamificationRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  LeaderboardCubit(this._repository) : super(const LeaderboardState());

  Future<void> loadIfNeeded() async {
    if (state.status == LeaderboardStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    emit(state.copyWith(status: LeaderboardStatus.loading));
    try {
      final entries = await _repository.fetchLeaderboard(
        state.weekly ? 'weekly' : 'monthly',
        offset: 0,
        limit: 20,
      );
      emit(
        LeaderboardState(
          status: LeaderboardStatus.loaded,
          entries: entries,
          weekly: state.weekly,
          hasReachedMax: entries.length < 20,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.error,
          entries: [],
          errorMessage: 'Unable to load leaderboard.',
        ),
      );
    }
  }

  Future<void> loadMoreLeaderboard() async {
    if (state.hasReachedMax || state.status == LeaderboardStatus.loading) return;

    try {
      final newEntries = await _repository.fetchLeaderboard(
        state.weekly ? 'weekly' : 'monthly',
        offset: state.entries.length,
        limit: 20,
      );
      
      // Deduplicate by studentId, sort by rank
      final allEntriesMap = { for (var e in state.entries) e.studentId: e };
      for (var e in newEntries) {
        allEntriesMap[e.studentId] = e;
      }
      
      final updatedEntries = allEntriesMap.values.toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));
        
      emit(
        state.copyWith(
          status: LeaderboardStatus.loaded,
          entries: updatedEntries,
          hasReachedMax: newEntries.length < 20,
        ),
      );
    } catch (_) {}
  }

  Future<void> togglePeriod() async {
    emit(state.copyWith(weekly: !state.weekly));
    await loadLeaderboard();
  }
}
