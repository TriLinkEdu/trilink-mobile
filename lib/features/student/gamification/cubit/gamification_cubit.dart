import 'package:flutter_bloc/flutter_bloc.dart';

import '../../exams/models/exam_model.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import 'gamification_state.dart';

export 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final StudentGamificationRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  GamificationCubit(this._repository) : super(const GamificationState());

  Future<void> loadIfNeeded() async {
    if (state.status == GamificationStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadAll();
  }

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
        _repository.fetchDailyMissions(),
        _repository.fetchTeamChallenge(),
        _repository.fetchXpProgress(),
        _repository.fetchNextBadgeProgress(),
        _repository.fetchBadges(),
        _repository.fetchStudentBadges('s1'),
      ]);
      emit(
        GamificationState(
          status: GamificationStatus.loaded,
          streak: results[0] as StreakModel,
          achievements: results[1] as List<AchievementModel>,
          leaderboardEntries: results[2] as List<LeaderboardEntry>,
          availableQuizzes: results[3] as List<QuizModel>,
          dailyMissions: results[4] as List<DailyMissionModel>,
          teamChallenge: results[5] as TeamChallengeModel?,
          xpProgress: results[6] as XpProgressModel,
          nextBadgeProgress: results[7] as NextBadgeProgressModel?,
          badges: results[8] as List<BadgeModel>,
          studentBadges: results[9] as List<StudentBadgeModel>,
          isWeeklyRanking: state.isWeeklyRanking,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: GamificationStatus.error,
          errorMessage: 'Unable to load gamification data: $e',
        ),
      );
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
    } catch (e) {
      emit(
        state.copyWith(
          isWeeklyRanking: !next,
          errorMessage: 'Unable to switch leaderboard period: $e',
        ),
      );
    }
  }

  Future<void> completeMission(String missionId) async {
    try {
      final mutation = await _repository.markMissionCompleted(missionId);
      final refreshed = await Future.wait([
        _repository.fetchDailyMissions(),
        _repository.fetchXpProgress(),
        _repository.fetchNextBadgeProgress(),
        _repository.fetchAchievements(),
        _repository.fetchStudentBadges('s1'),
        _repository.fetchLeaderboard(
          state.isWeeklyRanking ? 'weekly' : 'monthly',
        ),
      ]);
      emit(
        state.copyWith(
          dailyMissions: refreshed[0] as List<DailyMissionModel>,
          xpProgress: refreshed[1] as XpProgressModel,
          nextBadgeProgress: refreshed[2] as NextBadgeProgressModel?,
          achievements: refreshed[3] as List<AchievementModel>,
          studentBadges: refreshed[4] as List<StudentBadgeModel>,
          leaderboardEntries: refreshed[5] as List<LeaderboardEntry>,
          newlyUnlockedAchievementIds: mutation.newAchievementIds,
          newlyUnlockedBadgeIds: mutation.newBadgeIds,
          leaderboardDelta:
              mutation.leaderboardBeforeRank != null &&
                  mutation.leaderboardAfterRank != null
              ? mutation.leaderboardBeforeRank! - mutation.leaderboardAfterRank!
              : null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to complete mission: $e'));
    }
  }

  Future<void> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
    required Map<String, int> answerMap,
  }) async {
    try {
      final mutation = await _repository.applyQuizOutcome(
        quizId: quizId,
        subjectId: subjectId,
        result: ExamResultModel(
          examId: quizId,
          examTitle: '',
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          score: score.toDouble(),
          xpEarned: xpEarned,
          answerMap: answerMap,
        ),
      );

      final refreshed = await Future.wait([
        _repository.fetchAchievements(),
        _repository.fetchDailyMissions(),
        _repository.fetchXpProgress(),
        _repository.fetchNextBadgeProgress(),
        _repository.fetchStudentBadges('s1'),
        _repository.fetchLeaderboard(
          state.isWeeklyRanking ? 'weekly' : 'monthly',
        ),
      ]);

      emit(
        state.copyWith(
          achievements: refreshed[0] as List<AchievementModel>,
          dailyMissions: refreshed[1] as List<DailyMissionModel>,
          xpProgress: refreshed[2] as XpProgressModel,
          nextBadgeProgress: refreshed[3] as NextBadgeProgressModel?,
          studentBadges: refreshed[4] as List<StudentBadgeModel>,
          leaderboardEntries: refreshed[5] as List<LeaderboardEntry>,
          newlyUnlockedAchievementIds: mutation.newAchievementIds,
          newlyUnlockedBadgeIds: mutation.newBadgeIds,
          leaderboardDelta:
              mutation.leaderboardBeforeRank != null &&
                  mutation.leaderboardAfterRank != null
              ? mutation.leaderboardBeforeRank! - mutation.leaderboardAfterRank!
              : null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to update progress: $e'));
    }
  }
}
