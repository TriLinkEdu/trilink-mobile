import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_gamification_repository.dart';
import 'achievements_list_state.dart';

export 'achievements_list_state.dart';

class AchievementsListCubit extends Cubit<AchievementsListState> {
  final StudentGamificationRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  AchievementsListCubit(this._repository)
    : super(const AchievementsListState());

  Future<void> loadIfNeeded() async {
    if (state.status == AchievementsListStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadAchievements();
  }

  Future<void> loadAchievements() async {
    emit(state.copyWith(status: AchievementsListStatus.loading));
    try {
      final achievements = await _repository.fetchAchievements();
      emit(
        AchievementsListState(
          status: AchievementsListStatus.loaded,
          achievements: achievements,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: AchievementsListStatus.error,
          achievements: [],
          errorMessage: 'Unable to load achievements.',
        ),
      );
    }
  }
}
