import '../models/gamification_models.dart';
import '../../exams/models/exam_model.dart';

abstract class StudentGamificationRepository {
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period);
  Future<List<AchievementModel>> fetchAchievements();
  Future<ExamModel> fetchQuiz(String subjectId);
  Future<ExamResultModel> submitQuizAnswers(
      String quizId, Map<String, int> answers);
  Future<StreakModel> fetchStreak();
  Future<List<QuizModel>> fetchAvailableQuizzes();
}
