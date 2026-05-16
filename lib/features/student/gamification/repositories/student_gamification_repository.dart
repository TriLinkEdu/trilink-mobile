import '../models/gamification_models.dart';
import '../../exams/models/exam_model.dart';

/// Strongly-typed payload returned by the BFF hub endpoint.
/// Carries the complete Gamification Hub state in a single object.
class GamificationHubPayload {
  final StreakModel streak;
  final List<AchievementModel> achievements;
  final List<LeaderboardEntry> leaderboardEntries;
  final List<QuizModel> availableQuizzes;
  final List<DailyMissionModel> dailyMissions;
  final TeamChallengeModel? teamChallenge;
  final XpProgressModel xpProgress;
  final NextBadgeProgressModel? nextBadgeProgress;
  final List<BadgeModel> badges;
  final List<StudentBadgeModel> studentBadges;

  const GamificationHubPayload({
    required this.streak,
    required this.achievements,
    required this.leaderboardEntries,
    required this.availableQuizzes,
    required this.dailyMissions,
    required this.teamChallenge,
    required this.xpProgress,
    required this.nextBadgeProgress,
    required this.badges,
    required this.studentBadges,
  });
}

abstract class StudentGamificationRepository {
  /// Single BFF call — returns the complete Hub state in one request.
  Future<GamificationHubPayload> fetchHub();

  // Individual endpoints — still used for targeted refreshes after mutations.
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period, {int offset = 0, int limit = 50});
  Future<List<AchievementModel>> fetchAchievements();
  Future<List<DailyMissionModel>> fetchDailyMissions();
  Future<TeamChallengeModel?> fetchTeamChallenge();
  Future<XpProgressModel> fetchXpProgress();
  Future<NextBadgeProgressModel?> fetchNextBadgeProgress();
  Future<ExamModel> fetchQuiz(String subjectId);
  Future<ExamResultModel> submitQuizAnswers(
    String quizId,
    Map<String, int> answers,
  );
  Future<GamificationMutationResult> markMissionCompleted(String missionId);
  Future<GamificationMutationResult> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required ExamResultModel result,
  });
  Future<StreakModel> fetchStreak();
  Future<List<QuizModel>> fetchAvailableQuizzes();
  Future<List<BadgeModel>> fetchBadges();
  Future<List<StudentBadgeModel>> fetchStudentBadges(String studentId);

  void clearCache() {}
}
