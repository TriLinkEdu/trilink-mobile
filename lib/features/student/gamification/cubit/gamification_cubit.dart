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
    emit(state.copyWith(status: GamificationStatus.loading, errorMessage: null));
    try {
      final userId = await _currentUserId();
      final hub = await _repository.fetchHub();

      emit(
        state.copyWith(
          status: GamificationStatus.loaded,
          currentUserId: userId,
          streak: hub.streak,
          xpProgress: hub.xpProgress,
          nextBadgeProgress: hub.nextBadgeProgress,
          dailyMissions: hub.dailyMissions,
          achievements: hub.achievements,
          leaderboardEntries: hub.leaderboardEntries,
          availableQuizzes: hub.availableQuizzes,
          teamChallenge: hub.teamChallenge,
          badges: hub.badges,
          studentBadges: hub.studentBadges,
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
      final dailyMissions = await _safeFetch(_repository.fetchDailyMissions);
      final xpProgress = await _safeFetch(_repository.fetchXpProgress);
      final nextBadge = await _safeFetch(_repository.fetchNextBadgeProgress);
      final achievements = await _safeFetch(_repository.fetchAchievements);
      final studentBadges = await _safeFetch(
        () => _repository.fetchStudentBadges(userId),
      );
      final leaderboard = await _safeFetch(
        () => _repository.fetchLeaderboard(
          state.isWeeklyRanking ? 'weekly' : 'monthly',
        ),
      );

      emit(
        state.copyWith(
          dailyMissions: dailyMissions ?? state.dailyMissions,
          xpProgress: xpProgress ?? state.xpProgress,
          nextBadgeProgress: nextBadge ?? state.nextBadgeProgress,
          achievements: achievements ?? state.achievements,
          studentBadges: studentBadges ?? state.studentBadges,
          leaderboardEntries: leaderboard ?? state.leaderboardEntries,
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
      final achievements = await _safeFetch(_repository.fetchAchievements);
      final dailyMissions = await _safeFetch(_repository.fetchDailyMissions);
      final xpProgress = await _safeFetch(_repository.fetchXpProgress);
      final nextBadge = await _safeFetch(_repository.fetchNextBadgeProgress);
      final studentBadges = await _safeFetch(
        () => _repository.fetchStudentBadges(userId),
      );
      final leaderboard = await _safeFetch(
        () => _repository.fetchLeaderboard(
          state.isWeeklyRanking ? 'weekly' : 'monthly',
        ),
      );

      emit(
        state.copyWith(
          achievements: achievements ?? state.achievements,
          dailyMissions: dailyMissions ?? state.dailyMissions,
          xpProgress: xpProgress ?? state.xpProgress,
          nextBadgeProgress: nextBadge ?? state.nextBadgeProgress,
          studentBadges: studentBadges ?? state.studentBadges,
          leaderboardEntries: leaderboard ?? state.leaderboardEntries,
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

  Future<T?> _safeFetch<T>(Future<T> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }
}
