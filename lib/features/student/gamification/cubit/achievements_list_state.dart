import 'package:equatable/equatable.dart';

import '../models/gamification_models.dart';

enum AchievementsListStatus { initial, loading, loaded, error }

class AchievementsListState extends Equatable {
  final AchievementsListStatus status;
  final List<AchievementModel> achievements;
  final String? errorMessage;

  const AchievementsListState({
    this.status = AchievementsListStatus.initial,
    this.achievements = const [],
    this.errorMessage,
  });

  AchievementsListState copyWith({
    AchievementsListStatus? status,
    List<AchievementModel>? achievements,
    String? errorMessage,
  }) {
    return AchievementsListState(
      status: status ?? this.status,
      achievements: achievements ?? this.achievements,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, achievements, errorMessage];
}
