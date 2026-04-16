import 'package:equatable/equatable.dart';

import '../models/gamification_models.dart';

enum GamificationStatus { initial, loading, loaded, error }

class GamificationState extends Equatable {
  final GamificationStatus status;
  final StreakModel? streak;
  final List<AchievementModel> achievements;
  final List<LeaderboardEntry> leaderboardEntries;
  final List<QuizModel> availableQuizzes;
  final List<DailyMissionModel> dailyMissions;
  final TeamChallengeModel? teamChallenge;
  final XpProgressModel? xpProgress;
  final NextBadgeProgressModel? nextBadgeProgress;
  final List<BadgeModel> badges;
  final List<StudentBadgeModel> studentBadges;
  final List<String> newlyUnlockedAchievementIds;
  final List<String> newlyUnlockedBadgeIds;
  final int? leaderboardDelta;
  final bool isWeeklyRanking;
  final String? errorMessage;

  const GamificationState({
    this.status = GamificationStatus.initial,
    this.streak,
    this.achievements = const [],
    this.leaderboardEntries = const [],
    this.availableQuizzes = const [],
    this.dailyMissions = const [],
    this.teamChallenge,
    this.xpProgress,
    this.nextBadgeProgress,
    this.badges = const [],
    this.studentBadges = const [],
    this.newlyUnlockedAchievementIds = const [],
    this.newlyUnlockedBadgeIds = const [],
    this.leaderboardDelta,
    this.isWeeklyRanking = true,
    this.errorMessage,
  });

  GamificationState copyWith({
    GamificationStatus? status,
    StreakModel? streak,
    List<AchievementModel>? achievements,
    List<LeaderboardEntry>? leaderboardEntries,
    List<QuizModel>? availableQuizzes,
    List<DailyMissionModel>? dailyMissions,
    TeamChallengeModel? teamChallenge,
    XpProgressModel? xpProgress,
    NextBadgeProgressModel? nextBadgeProgress,
    List<BadgeModel>? badges,
    List<StudentBadgeModel>? studentBadges,
    List<String>? newlyUnlockedAchievementIds,
    List<String>? newlyUnlockedBadgeIds,
    int? leaderboardDelta,
    bool? isWeeklyRanking,
    String? errorMessage,
  }) {
    return GamificationState(
      status: status ?? this.status,
      streak: streak ?? this.streak,
      achievements: achievements ?? this.achievements,
      leaderboardEntries: leaderboardEntries ?? this.leaderboardEntries,
      availableQuizzes: availableQuizzes ?? this.availableQuizzes,
      dailyMissions: dailyMissions ?? this.dailyMissions,
      teamChallenge: teamChallenge ?? this.teamChallenge,
      xpProgress: xpProgress ?? this.xpProgress,
      nextBadgeProgress: nextBadgeProgress ?? this.nextBadgeProgress,
      badges: badges ?? this.badges,
      studentBadges: studentBadges ?? this.studentBadges,
      newlyUnlockedAchievementIds:
          newlyUnlockedAchievementIds ?? this.newlyUnlockedAchievementIds,
      newlyUnlockedBadgeIds:
          newlyUnlockedBadgeIds ?? this.newlyUnlockedBadgeIds,
      leaderboardDelta: leaderboardDelta ?? this.leaderboardDelta,
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
    dailyMissions,
    teamChallenge,
    xpProgress,
    nextBadgeProgress,
    badges,
    studentBadges,
    newlyUnlockedAchievementIds,
    newlyUnlockedBadgeIds,
    leaderboardDelta,
    isWeeklyRanking,
    errorMessage,
  ];
}
