import '../../exams/models/exam_model.dart';
import '../models/gamification_models.dart';
import '../../shared/models/student_progress_model.dart';
import '../../shared/repositories/student_progress_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import 'student_gamification_repository.dart';

class RealStudentGamificationRepository
    implements StudentGamificationRepository {
  final StudentProgressRepository _progressRepository;
  final StudentGamificationRepository _fallback;
  final ApiClient _apiClient = sl<ApiClient>();

  static const Duration _ttl = Duration(seconds: 30);

  static DateTime? _fetchedAt;
  static Future<void>? _inFlight;

  static StreakModel? _streak;
  static XpProgressModel? _xpProgress;
  static List<BadgeModel>? _badges;
  static List<StudentBadgeModel>? _studentBadges;
  static List<AchievementModel>? _achievements;
  static List<LeaderboardEntry>? _leaderboardWeekly;
  static List<LeaderboardEntry>? _leaderboardMonthly;

  RealStudentGamificationRepository({
    required StudentProgressRepository progressRepository,
    required StudentGamificationRepository fallback,
  }) : _progressRepository = progressRepository,
       _fallback = fallback;

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.gamificationLeaderboard}?academicYearId=2024&limit=20'
      );
      
      if (response is List && response.isNotEmpty) {
        final responseList = response as List;
        return responseList.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value as Map<String, dynamic>;
          return LeaderboardEntry(
            studentId: data['userId']?.toString() ?? 'api_user_$index',
            studentName: data['name']?.toString() ?? 'API Student ${index + 1}',
            rank: index + 1,
            points: (data['averageScore'] ?? data['points'] ?? 0).round(),
            scope: LeaderboardScope.school,
            period: LeaderboardPeriod.weekly,
          );
        }).toList();
      }
    } catch (e) {
      print('Leaderboard API error: $e');
    }
    
    // Fallback to mock data
    return await _fallback.fetchLeaderboard(period);
  }

  @override
  Future<List<AchievementModel>> fetchAchievements() async {
    await _loadCore();
    return _achievements ?? const [];
  }

  @override
  Future<List<DailyMissionModel>> fetchDailyMissions() {
    // Dedicated endpoint missing; keep fallback behavior.
    return _fallback.fetchDailyMissions();
  }

  @override
  Future<TeamChallengeModel?> fetchTeamChallenge() {
    // Dedicated endpoint missing; keep fallback behavior.
    return _fallback.fetchTeamChallenge();
  }

  @override
  Future<XpProgressModel> fetchXpProgress() async {
    await _loadCore();
    return _xpProgress ??
        const XpProgressModel(
          level: 1,
          totalXp: 0,
          xpIntoCurrentLevel: 0,
          xpNeededForNextLevel: 100,
          weeklyXpTarget: 300,
          weeklyXpEarned: 0,
        );
  }

  @override
  Future<NextBadgeProgressModel?> fetchNextBadgeProgress() {
    // Not derivable reliably from existing endpoints.
    return _fallback.fetchNextBadgeProgress();
  }

  @override
  Future<ExamModel> fetchQuiz(String subjectId) {
    // Gamification quiz endpoints missing.
    return _fallback.fetchQuiz(subjectId);
  }

  @override
  Future<ExamResultModel> submitQuizAnswers(
    String quizId,
    Map<String, int> answers,
  ) {
    return _fallback.submitQuizAnswers(quizId, answers);
  }

  @override
  Future<GamificationMutationResult> markMissionCompleted(String missionId) {
    return _fallback.markMissionCompleted(missionId);
  }

  @override
  Future<GamificationMutationResult> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required ExamResultModel result,
  }) {
    return _fallback.applyQuizOutcome(
      quizId: quizId,
      subjectId: subjectId,
      result: result,
    );
  }

  @override
  Future<StreakModel> fetchStreak() async {
    await _loadCore();
    return _streak ??
        const StreakModel(currentStreak: 0, longestStreak: 0, recentDays: []);
  }

  @override
  Future<List<QuizModel>> fetchAvailableQuizzes() {
    return _fallback.fetchAvailableQuizzes();
  }

  @override
  Future<List<BadgeModel>> fetchBadges() async {
    await _loadCore();
    return _badges ?? const [];
  }

  @override
  Future<List<StudentBadgeModel>> fetchStudentBadges(String studentId) async {
    await _loadCore();
    return _studentBadges ?? const [];
  }

  Future<void> _loadCore() async {
    if (_fetchedAt != null && DateTime.now().difference(_fetchedAt!) < _ttl) {
      return;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _loadCoreFresh();
    _inFlight = future;
    await future;
    _inFlight = null;
  }

  Future<void> _loadCoreFresh() async {
    final progress = await _safeProgress();
    final badges = await _safeBadges();
    final studentBadges = await _safeStudentBadges();
    final leaderboard = await _safeLeaderboard();

    _streak = StreakModel(
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      recentDays: _recentDays(progress.currentStreak),
    );

    final weeklyEarned = _estimateWeekly(progress.totalXp);
    _xpProgress = XpProgressModel(
      level: progress.level,
      totalXp: progress.totalXp,
      xpIntoCurrentLevel: progress.totalXp % 100,
      xpNeededForNextLevel: 100,
      weeklyXpTarget: 300,
      weeklyXpEarned: weeklyEarned,
    );

    _badges = badges;
    _studentBadges = studentBadges;
    _leaderboardWeekly = leaderboard;
    _leaderboardMonthly = leaderboard;

    _achievements = _deriveAchievements(
      progress: progress,
      allBadges: badges,
      earnedBadges: studentBadges,
      leaderboardEntries: leaderboard,
    );

    _fetchedAt = DateTime.now();
  }

  Future<StudentProgressModel> _safeProgress() async {
    try {
      return await _progressRepository.fetchProgress();
    } catch (_) {
      return const StudentProgressModel(
        currentStreak: 0,
        longestStreak: 0,
        totalXp: 0,
        level: 1,
        levelTitle: 'Starter',
      );
    }
  }

  Future<List<BadgeModel>> _safeBadges() async {
    try {
      return await _fallback.fetchBadges();
    } catch (_) {
      return const [];
    }
  }

  Future<List<StudentBadgeModel>> _safeStudentBadges() async {
    try {
      return await _fallback.fetchStudentBadges('me');
    } catch (_) {
      return const [];
    }
  }

  Future<List<LeaderboardEntry>> _safeLeaderboard() async {
    try {
      return await _fallback.fetchLeaderboard('weekly');
    } catch (_) {
      return const [];
    }
  }

  List<AchievementModel> _deriveAchievements({
    required StudentProgressModel progress,
    required List<BadgeModel> allBadges,
    required List<StudentBadgeModel> earnedBadges,
    required List<LeaderboardEntry> leaderboardEntries,
  }) {
    final leaderboardRank = _rankOfMe(leaderboardEntries);
    final earnedCount = earnedBadges.length;

    final streakTarget = 7;
    final xpTarget = 500;
    final badgeTarget = allBadges.isEmpty ? 1 : allBadges.length;

    return [
      AchievementModel(
        id: 'ach-streak-7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak.',
        iconUrl: 'assets/achievements/week_warrior.png',
        category: AchievementCategory.consistency,
        progressCurrent: progress.currentStreak,
        progressTarget: streakTarget,
        isUnlocked: progress.currentStreak >= streakTarget,
      ),
      AchievementModel(
        id: 'ach-xp-500',
        title: 'XP Builder',
        description: 'Reach 500 total XP.',
        iconUrl: 'assets/achievements/legend.png',
        category: AchievementCategory.milestone,
        progressCurrent: progress.totalXp,
        progressTarget: xpTarget,
        isUnlocked: progress.totalXp >= xpTarget,
      ),
      AchievementModel(
        id: 'ach-badges-collected',
        title: 'Badge Collector',
        description: 'Collect all available badges.',
        iconUrl: 'assets/achievements/top_class.png',
        category: AchievementCategory.exploration,
        progressCurrent: earnedCount,
        progressTarget: badgeTarget,
        isUnlocked: earnedCount >= badgeTarget,
      ),
      AchievementModel(
        id: 'ach-leaderboard-top10',
        title: 'Top Ten',
        description: 'Reach top 10 on leaderboard.',
        iconUrl: 'assets/achievements/social_learner.png',
        category: AchievementCategory.social,
        progressCurrent: leaderboardRank == null ? 0 : 1,
        progressTarget: 1,
        isUnlocked: leaderboardRank != null && leaderboardRank <= 10,
      ),
    ];
  }

  int? _rankOfMe(List<LeaderboardEntry> entries) {
    for (final e in entries) {
      if (e.studentId == 'me') return e.rank;
    }
    return null;
  }

  List<DateTime> _recentDays(int currentStreak) {
    final now = DateTime.now();
    final activeDays = currentStreak.clamp(0, 7);
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      return day;
    }).skip(7 - activeDays).toList();
  }

  int _estimateWeekly(int totalXp) {
    final estimate = (totalXp * 0.15).round();
    return estimate.clamp(0, 300);
  }
}
