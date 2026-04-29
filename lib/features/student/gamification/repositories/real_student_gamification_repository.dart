import 'package:flutter/foundation.dart';

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

  RealStudentGamificationRepository({
    required StudentProgressRepository progressRepository,
    required StudentGamificationRepository fallback,
  }) : _progressRepository = progressRepository,
       _fallback = fallback;

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period) async {
    try {
      if (period == 'weekly') {
        final raw = await _apiClient.get(
          '${ApiConstants.gamificationStreakLeaderboard}?limit=20',
        );
        final entries = (raw['entries'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => LeaderboardEntry(
                studentId: (e['userId'] ?? '').toString(),
                studentName:
                    '${(e['user']?['firstName'] ?? '').toString()} ${(e['user']?['lastName'] ?? '').toString()}'
                        .trim()
                        .isEmpty
                    ? 'Student'
                    : '${(e['user']?['firstName'] ?? '').toString()} ${(e['user']?['lastName'] ?? '').toString()}'
                          .trim(),
                rank: _asInt(e['rank'], fallback: 0),
                points: _asInt(e['currentStreak'], fallback: 0),
                scope: LeaderboardScope.school,
                period: LeaderboardPeriod.weekly,
              ),
            )
            .toList();
        if (entries.isNotEmpty) return entries;
      }

      final raw = await _apiClient.get(
        '${ApiConstants.gamificationLeaderboard}?academicYearId=2024&limit=20',
      );
      final entries = (raw['entries'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => LeaderboardEntry(
              studentId: (e['studentId'] ?? '').toString(),
              studentName:
                  '${(e['student']?['firstName'] ?? '').toString()} ${(e['student']?['lastName'] ?? '').toString()}'
                      .trim()
                      .isEmpty
                  ? 'Student'
                  : '${(e['student']?['firstName'] ?? '').toString()} ${(e['student']?['lastName'] ?? '').toString()}'
                        .trim(),
              rank: _asInt(e['rank'], fallback: 0),
              points: _asInt(e['averageScore'], fallback: 0),
              scope: LeaderboardScope.school,
              period: period == 'monthly'
                  ? LeaderboardPeriod.monthly
                  : LeaderboardPeriod.weekly,
            ),
          )
          .toList();
      if (entries.isNotEmpty) {
        return entries;
      }
    } catch (e) {
      debugPrint('Leaderboard API error: $e');
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
  Future<List<DailyMissionModel>> fetchDailyMissions() async {
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationMissions);
      final missions = rows
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => DailyMissionModel(
              id: (m['id'] ?? '').toString(),
              title: (m['title'] ?? 'Mission').toString(),
              description: (m['description'] ?? '').toString(),
              xpReward: _asInt(m['xpReward'], fallback: 0),
              isCompleted: (m['isCompleted'] == true),
              progressCurrent: _asInt(m['progressCurrent'], fallback: 0),
              progressTarget: _asInt(m['progressTarget'], fallback: 1),
            ),
          )
          .toList();
      if (missions.isNotEmpty) return missions;
    } catch (_) {}
    return _fallback.fetchDailyMissions();
  }

  @override
  Future<TeamChallengeModel?> fetchTeamChallenge() async {
    try {
      final raw = await _apiClient.get(ApiConstants.gamificationTeamChallenge);
      return TeamChallengeModel(
        id: (raw['id'] ?? '').toString(),
        title: (raw['title'] ?? 'Team Challenge').toString(),
        objective: (raw['objective'] ?? '').toString(),
        progressCurrent: _asInt(raw['progressCurrent'], fallback: 0),
        progressTarget: _asInt(raw['progressTarget'], fallback: 1),
        contributorCount: _asInt(raw['contributorCount'], fallback: 0),
        endsAt:
            DateTime.tryParse((raw['endsAt'] ?? '').toString()) ??
            DateTime.now().add(const Duration(days: 1)),
      );
    } catch (_) {
      return _fallback.fetchTeamChallenge();
    }
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
    return _fetchQuizBySubject(subjectId);
  }

  @override
  Future<ExamResultModel> submitQuizAnswers(
    String quizId,
    Map<String, int> answers,
  ) async {
    try {
      final raw = await _apiClient.post(
        ApiConstants.gamificationQuizSubmit(quizId),
        data: {'answers': answers},
      );
      final resultRaw = (raw['result'] is Map<String, dynamic>)
          ? raw['result'] as Map<String, dynamic>
          : raw;
      return ExamResultModel(
        examId: (resultRaw['examId'] ?? quizId).toString(),
        examTitle: (resultRaw['examTitle'] ?? 'Quick Quiz').toString(),
        totalQuestions: _asInt(resultRaw['totalQuestions'], fallback: 0),
        correctAnswers: _asInt(resultRaw['correctAnswers'], fallback: 0),
        score: _asDouble(resultRaw['score'], fallback: 0),
        xpEarned: _asInt(resultRaw['xpEarned'], fallback: 0),
        answerMap:
            (resultRaw['answerMap'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), _asInt(v, fallback: 0)),
            ) ??
            answers,
      );
    } catch (_) {
      return _fallback.submitQuizAnswers(quizId, answers);
    }
  }

  @override
  Future<GamificationMutationResult> markMissionCompleted(
    String missionId,
  ) async {
    try {
      final raw = await _apiClient.post(
        ApiConstants.gamificationMissionComplete(missionId),
      );
      return _mapMutation(raw);
    } catch (_) {
      return _fallback.markMissionCompleted(missionId);
    }
  }

  @override
  Future<GamificationMutationResult> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required ExamResultModel result,
  }) async {
    try {
      final raw = await _apiClient.post(
        ApiConstants.gamificationQuizSubmit(quizId),
        data: {'answers': result.answerMap},
      );
      if (raw['mutation'] is Map<String, dynamic>) {
        return _mapMutation(raw['mutation'] as Map<String, dynamic>);
      }
      return _mapMutation(raw);
    } catch (_) {
      return _fallback.applyQuizOutcome(
        quizId: quizId,
        subjectId: subjectId,
        result: result,
      );
    }
  }

  @override
  Future<StreakModel> fetchStreak() async {
    await _loadCore();
    return _streak ??
        const StreakModel(currentStreak: 0, longestStreak: 0, recentDays: []);
  }

  @override
  Future<List<QuizModel>> fetchAvailableQuizzes() async {
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationQuizzes);
      final quizzes = rows
          .whereType<Map<String, dynamic>>()
          .map(
            (q) => QuizModel(
              id: (q['id'] ?? '').toString(),
              title: (q['title'] ?? 'Quick Quiz').toString(),
              subjectId: (q['subjectId'] ?? '').toString(),
              subjectName: (q['subjectName'] ?? 'Subject').toString(),
              chapterId: q['chapterId']?.toString(),
              questionCount: _asInt(q['questionCount'], fallback: 0),
              xpReward: _asInt(q['xpReward'], fallback: 0),
              difficulty: (q['difficulty'] ?? 'medium').toString(),
            ),
          )
          .toList();
      if (quizzes.isNotEmpty) return quizzes;
    } catch (_) {}
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
      final rows = await _apiClient.getList(ApiConstants.gamificationBadges);
      final mapped = rows
          .whereType<Map<String, dynamic>>()
          .map(
            (b) => BadgeModel(
              id: (b['id'] ?? '').toString(),
              name: (b['name'] ?? 'Badge').toString(),
              description: (b['description'] ?? '').toString(),
              iconUrl: (b['iconKey'] ?? 'badge').toString(),
              xpValue: _asInt(b['pointsValue'], fallback: 0),
            ),
          )
          .toList();
      if (mapped.isNotEmpty) return mapped;
    } catch (_) {
      // fall through
    }
    return _fallback.fetchBadges();
  }

  Future<List<StudentBadgeModel>> _safeStudentBadges() async {
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationMyBadges);
      final mapped = rows.whereType<Map<String, dynamic>>().map((row) {
        final badgeRaw =
            (row['badge'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        return StudentBadgeModel(
          studentId: (row['userId'] ?? row['studentId'] ?? 'me').toString(),
          badge: BadgeModel(
            id: (badgeRaw['id'] ?? '').toString(),
            name: (badgeRaw['name'] ?? 'Badge').toString(),
            description: (badgeRaw['description'] ?? '').toString(),
            iconUrl: (badgeRaw['iconKey'] ?? 'badge').toString(),
            xpValue: _asInt(badgeRaw['pointsValue'], fallback: 0),
          ),
          awardedAt:
              DateTime.tryParse((row['awardedAt'] ?? '').toString()) ??
              DateTime.now(),
        );
      }).toList();
      if (mapped.isNotEmpty) return mapped;
    } catch (_) {
      // fall through
    }
    return _fallback.fetchStudentBadges('me');
  }

  Future<List<LeaderboardEntry>> _safeLeaderboard() async {
    try {
      return await fetchLeaderboard('weekly');
    } catch (_) {
      return _fallback.fetchLeaderboard('weekly');
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

  Future<ExamModel> _fetchQuizBySubject(String subjectId) async {
    try {
      final quizzes = await fetchAvailableQuizzes();
      String? quizId;
      for (final q in quizzes) {
        if (q.subjectId == subjectId) {
          quizId = q.id;
          break;
        }
      }
      quizId ??= quizzes.isNotEmpty ? quizzes.first.id : null;
      if (quizId == null) {
        return _fallback.fetchQuiz(subjectId);
      }
      final raw = await _apiClient.get(
        ApiConstants.gamificationQuizById(quizId),
      );
      return _mapExam(raw);
    } catch (_) {
      return _fallback.fetchQuiz(subjectId);
    }
  }

  ExamModel _mapExam(Map<String, dynamic> raw) {
    final questionRows = (raw['questions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final questions = questionRows
        .map(
          (q) => QuestionModel(
            id: (q['id'] ?? '').toString(),
            text: (q['text'] ?? '').toString(),
            options: (q['options'] as List? ?? const [])
                .map((o) => o.toString())
                .toList(),
            correctIndex: _asInt(q['correctIndex'], fallback: 0),
            pointValue: _asDouble(q['pointValue'], fallback: 1),
          ),
        )
        .toList();

    return ExamModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Quick Quiz').toString(),
      subjectId: (raw['subjectId'] ?? '').toString(),
      subjectName: (raw['subjectName'] ?? 'Subject').toString(),
      durationMinutes: _asInt(raw['durationMinutes'], fallback: 10),
      questions: questions,
      lifecycleState: ExamLifecycleState.published,
      isTimeLimited: raw['isTimeLimited'] == true,
      isCompleted: false,
    );
  }

  GamificationMutationResult _mapMutation(Map<String, dynamic> raw) {
    return GamificationMutationResult(
      xpDelta: _asInt(raw['xpDelta'], fallback: 0),
      newTotalXp: _asInt(raw['newTotalXp'], fallback: 0),
      leveledUp: raw['leveledUp'] == true,
      newLevel: _asInt(raw['newLevel'], fallback: 0),
      newAchievementIds: (raw['newAchievementIds'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      newBadgeIds: (raw['newBadgeIds'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      leaderboardBeforeRank: raw['leaderboardBeforeRank'] == null
          ? null
          : _asInt(raw['leaderboardBeforeRank'], fallback: 0),
      leaderboardAfterRank: raw['leaderboardAfterRank'] == null
          ? null
          : _asInt(raw['leaderboardAfterRank'], fallback: 0),
    );
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
