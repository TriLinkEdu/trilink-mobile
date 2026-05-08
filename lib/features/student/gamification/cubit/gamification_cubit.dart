import 'package:flutter_bloc/flutter_bloc.dart';

import '../../exams/models/exam_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import 'gamification_state.dart';

export 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final StudentGamificationRepository _repository;
  final StorageService _storage = sl<StorageService>();
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  GamificationCubit(this._repository) : super(const GamificationState());

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

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
      final userId = await _currentUserId();

      // ── Single BFF request (replaces 10 parallel calls) ───────────────────
      final hub = await _repository.fetchHub();

      emit(
        GamificationState(
          status: GamificationStatus.loaded,
          currentUserId: userId,
          streak: hub.streak,
          achievements: hub.achievements,
          leaderboardEntries: hub.leaderboardEntries,
          availableQuizzes: hub.availableQuizzes,
          dailyMissions: hub.dailyMissions,
          teamChallenge: hub.teamChallenge,
          xpProgress: hub.xpProgress,
          nextBadgeProgress: hub.nextBadgeProgress,
          badges: hub.badges,
          studentBadges: hub.studentBadges,
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
      final userId = await _currentUserId();
      final refreshed = await Future.wait([
        _repository.fetchDailyMissions(),
        _repository.fetchXpProgress(),
        _repository.fetchNextBadgeProgress(),
        _repository.fetchAchievements(),
        _repository.fetchStudentBadges(userId),
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
      final userId = await _currentUserId();
      final refreshed = await Future.wait([
        _repository.fetchAchievements(),
        _repository.fetchDailyMissions(),
        _repository.fetchXpProgress(),
        _repository.fetchNextBadgeProgress(),
        _repository.fetchStudentBadges(userId),
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
