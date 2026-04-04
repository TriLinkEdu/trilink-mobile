import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_gamification_repository.dart';
import 'achievements_list_state.dart';

export 'achievements_list_state.dart';

class AchievementsListCubit extends Cubit<AchievementsListState> {
  final StudentGamificationRepository _repository;

  AchievementsListCubit(this._repository)
    : super(const AchievementsListState());

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
