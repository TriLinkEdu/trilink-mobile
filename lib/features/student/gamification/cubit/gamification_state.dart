import 'package:equatable/equatable.dart';

import '../models/gamification_models.dart';

enum GamificationStatus { initial, loading, loaded, error }

class GamificationState extends Equatable {
  final GamificationStatus status;
  final StreakModel? streak;
  final List<AchievementModel> achievements;
  final List<LeaderboardEntry> leaderboardEntries;
  final List<QuizModel> availableQuizzes;
  final bool isWeeklyRanking;
  final String? errorMessage;

  const GamificationState({
    this.status = GamificationStatus.initial,
    this.streak,
    this.achievements = const [],
    this.leaderboardEntries = const [],
    this.availableQuizzes = const [],
    this.isWeeklyRanking = true,
    this.errorMessage,
  });

  GamificationState copyWith({
    GamificationStatus? status,
    StreakModel? streak,
    List<AchievementModel>? achievements,
    List<LeaderboardEntry>? leaderboardEntries,
    List<QuizModel>? availableQuizzes,
    bool? isWeeklyRanking,
    String? errorMessage,
  }) {
    return GamificationState(
      status: status ?? this.status,
      streak: streak ?? this.streak,
      achievements: achievements ?? this.achievements,
      leaderboardEntries: leaderboardEntries ?? this.leaderboardEntries,
      availableQuizzes: availableQuizzes ?? this.availableQuizzes,
      isWeeklyRanking: isWeeklyRanking ?? this.isWeeklyRanking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        streak,
        achievements,
        leaderboardEntries,
        availableQuizzes,
        isWeeklyRanking,
        errorMessage,
      ];
}
