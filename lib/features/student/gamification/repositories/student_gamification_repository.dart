import '../models/gamification_models.dart';
import '../../exams/models/exam_model.dart';

abstract class StudentGamificationRepository {
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period);
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
}
