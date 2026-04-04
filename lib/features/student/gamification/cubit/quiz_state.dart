import 'package:equatable/equatable.dart';

import '../../exams/models/exam_model.dart';

enum QuizLoadStatus { initial, loading, loaded, error }

class QuizState extends Equatable {
  final QuizLoadStatus status;
  final ExamModel? quiz;
  final String? errorMessage;
  final bool submitting;
  final ExamResultModel? submitResult;
  final List<String> newlyUnlockedAchievements;
  final List<String> newlyUnlockedAchievementIds;
  final List<String> newlyUnlockedBadges;
  final List<String> newlyUnlockedBadgeIds;
  final bool leveledUp;
  final int? newLevel;
  final int? leaderboardDelta;

  const QuizState({
    this.status = QuizLoadStatus.initial,
    this.quiz,
    this.errorMessage,
    this.submitting = false,
    this.submitResult,
    this.newlyUnlockedAchievements = const [],
    this.newlyUnlockedAchievementIds = const [],
    this.newlyUnlockedBadges = const [],
    this.newlyUnlockedBadgeIds = const [],
    this.leveledUp = false,
    this.newLevel,
    this.leaderboardDelta,
  });

  QuizState copyWith({
    QuizLoadStatus? status,
    ExamModel? quiz,
    String? errorMessage,
    bool? submitting,
    ExamResultModel? submitResult,
    List<String>? newlyUnlockedAchievements,
    List<String>? newlyUnlockedAchievementIds,
    List<String>? newlyUnlockedBadges,
    List<String>? newlyUnlockedBadgeIds,
    bool? leveledUp,
    int? newLevel,
    int? leaderboardDelta,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      errorMessage: errorMessage,
      submitting: submitting ?? this.submitting,
      submitResult: submitResult,
      newlyUnlockedAchievements:
          newlyUnlockedAchievements ?? this.newlyUnlockedAchievements,
      newlyUnlockedAchievementIds:
          newlyUnlockedAchievementIds ?? this.newlyUnlockedAchievementIds,
      newlyUnlockedBadges: newlyUnlockedBadges ?? this.newlyUnlockedBadges,
      newlyUnlockedBadgeIds:
          newlyUnlockedBadgeIds ?? this.newlyUnlockedBadgeIds,
      leveledUp: leveledUp ?? this.leveledUp,
      newLevel: newLevel ?? this.newLevel,
      leaderboardDelta: leaderboardDelta ?? this.leaderboardDelta,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quiz,
    errorMessage,
    submitting,
    submitResult,
    newlyUnlockedAchievements,
    newlyUnlockedAchievementIds,
    newlyUnlockedBadges,
    newlyUnlockedBadgeIds,
    leveledUp,
    newLevel,
    leaderboardDelta,
  ];
}
