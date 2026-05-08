import '../../exams/models/exam_model.dart';
import '../models/gamification_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import 'student_gamification_repository.dart';

class RealStudentGamificationRepository
    implements StudentGamificationRepository {
  final ApiClient _apiClient;
  static final Map<String, GamificationMutationResult> _quizMutationCache = {};

  RealStudentGamificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? sl<ApiClient>();

  // ── BFF Hub ────────────────────────────────────────────────────────────────

  @override
  Future<GamificationHubPayload> fetchHub() async {
    final raw = await _apiClient.get(ApiConstants.gamificationHub);

    // ── Streak ───────────────────────────────────────────────────────────────
    final streakRaw = (raw['streak'] as Map<String, dynamic>?) ?? {};
    final currentStreak = _asInt(streakRaw['currentStreak'], fallback: 0);
    final longestStreak = _asInt(streakRaw['longestStreak'], fallback: 0);
    final lastLoginDateStr = (streakRaw['lastLoginDate'] ?? '').toString();
    final recentDays = <DateTime>[];
    if (currentStreak > 0 && lastLoginDateStr.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastLoginDateStr);
      if (lastDate != null) {
        final count = currentStreak.clamp(1, 7);
        for (var i = count - 1; i >= 0; i--) {
          recentDays.add(lastDate.subtract(Duration(days: i)));
        }
      }
    }
    final streak = StreakModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      recentDays: recentDays,
    );

    // ── Achievements ─────────────────────────────────────────────────────────
    final achievementRows =
        (raw['achievements'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final achievements = achievementRows
        .map((json) => AchievementModel.fromJson(json))
        .toList();

    // ── Leaderboard ──────────────────────────────────────────────────────────
    final lbRaw = raw['leaderboard'] as Map<String, dynamic>? ?? {};
    final lbRows =
        (lbRaw['entries'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final leaderboardEntries = lbRows.map((e) {
      final user = e['student'] as Map<String, dynamic>?;
      final firstName = (user?['firstName'] ?? '').toString();
      final lastName = (user?['lastName'] ?? '').toString();
      final displayName = '$firstName $lastName'.trim();
      return LeaderboardEntry(
        studentId: (e['userId'] ?? '').toString(),
        studentName: displayName.isEmpty ? 'Student' : displayName,
        rank: _asInt(e['rank'], fallback: 0),
        points: _asInt(e['points'], fallback: 0),
        scope: LeaderboardScope.classScope,
        period: LeaderboardPeriod.weekly,
      );
    }).toList();

    // ── Quizzes ───────────────────────────────────────────────────────────────
    final quizRows =
        (raw['availableQuizzes'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final availableQuizzes = quizRows.map((q) => QuizModel(
          id: (q['id'] ?? '').toString(),
          title: (q['title'] ?? 'Quick Quiz').toString(),
          subjectId: (q['subjectId'] ?? '').toString(),
          subjectName: (q['subjectName'] ?? 'Subject').toString(),
          chapterId: q['chapterId']?.toString(),
          questionCount: _asInt(q['questionCount'], fallback: 0),
          xpReward: _asInt(q['xpReward'], fallback: 0),
          difficulty: (q['difficulty'] ?? 'medium').toString(),
        )).toList();

    // ── Daily Missions ────────────────────────────────────────────────────────
    final missionRows =
        (raw['dailyMissions'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final dailyMissions = missionRows.map((m) => DailyMissionModel(
          id: (m['id'] ?? '').toString(),
          title: (m['title'] ?? 'Mission').toString(),
          description: (m['description'] ?? '').toString(),
          xpReward: _asInt(m['xpReward'], fallback: 0),
          isCompleted: m['isCompleted'] == true,
          progressCurrent: _asInt(m['progressCurrent'], fallback: 0),
          progressTarget: _asInt(m['progressTarget'], fallback: 1),
        )).toList();

    // ── Team Challenge ────────────────────────────────────────────────────────
    TeamChallengeModel? teamChallenge;
    final tcRaw = raw['teamChallenge'] as Map<String, dynamic>?;
    if (tcRaw != null && (tcRaw['id'] ?? '') != 'team-none') {
      teamChallenge = TeamChallengeModel(
        id: (tcRaw['id'] ?? '').toString(),
        title: (tcRaw['title'] ?? 'Class Weekly Sprint').toString(),
        objective: (tcRaw['objective'] ?? '').toString(),
        progressCurrent: _asInt(tcRaw['progressCurrent'], fallback: 0),
        progressTarget: _asInt(tcRaw['progressTarget'], fallback: 500),
        contributorCount: _asInt(tcRaw['contributorCount'], fallback: 0),
        endsAt: DateTime.tryParse((tcRaw['endsAt'] ?? '').toString()) ??
            DateTime.now().add(const Duration(days: 7)),
      );
    }

    // ── XP Progress ───────────────────────────────────────────────────────────
    final xpRaw = (raw['xpProgress'] as Map<String, dynamic>?) ?? {};
    final totalXp = _asInt(xpRaw['totalXp'], fallback: 0);
    final level = _asInt(xpRaw['level'], fallback: (totalXp ~/ 100).clamp(1, 999));
    final xpProgress = XpProgressModel(
      level: level,
      totalXp: totalXp,
      xpIntoCurrentLevel: _asInt(xpRaw['xpIntoCurrentLevel'], fallback: totalXp % 100),
      xpNeededForNextLevel: _asInt(xpRaw['xpNeededForNextLevel'], fallback: 100),
      weeklyXpTarget: _asInt(xpRaw['weeklyXpTarget'] ?? raw['weeklyXpTarget'], fallback: 300),
      weeklyXpEarned: _asInt(xpRaw['weeklyXpEarned'] ?? raw['weeklyXpEarned'], fallback: 0),
    );

    // ── Next Badge Progress ───────────────────────────────────────────────────
    NextBadgeProgressModel? nextBadgeProgress;
    final nbRaw = raw['nextBadgeProgress'] as Map<String, dynamic>?;
    if (nbRaw != null) {
      nextBadgeProgress = NextBadgeProgressModel(
        badgeName: (nbRaw['title'] ?? '').toString(),
        description: (nbRaw['title'] ?? '').toString(),
        progressCurrent: _asInt(nbRaw['progressCurrent'], fallback: 0),
        progressTarget: _asInt(nbRaw['progressTarget'], fallback: 1),
        xpReward: 0,
      );
    }

    // ── Badges ────────────────────────────────────────────────────────────────
    final badgeRows =
        (raw['badges'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final badges = badgeRows.map((b) => BadgeModel(
          id: (b['id'] ?? '').toString(),
          key: (b['key'] ?? '').toString(),
          name: (b['name'] ?? 'Badge').toString(),
          description: (b['description'] ?? '').toString(),
          iconUrl: (b['iconKey'] ?? 'badge').toString(),
          iconKey: (b['iconKey'] ?? '').toString(),
          xpValue: _asInt(b['pointsValue'], fallback: 0),
        )).toList();

    // ── Student Badges ────────────────────────────────────────────────────────
    final sbRows =
        (raw['studentBadges'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final studentBadges = sbRows.map((row) {
      final badgeRaw =
          (row['badge'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
      return StudentBadgeModel(
        studentId: (row['userId'] ?? row['studentId'] ?? 'me').toString(),
        badge: BadgeModel(
          id: (badgeRaw['id'] ?? '').toString(),
          key: (badgeRaw['key'] ?? '').toString(),
          name: (badgeRaw['name'] ?? 'Badge').toString(),
          description: (badgeRaw['description'] ?? '').toString(),
          iconUrl: (badgeRaw['iconKey'] ?? 'badge').toString(),
          iconKey: (badgeRaw['iconKey'] ?? '').toString(),
          xpValue: _asInt(badgeRaw['pointsValue'], fallback: 0),
        ),
        awardedAt: DateTime.tryParse((row['awardedAt'] ?? '').toString()) ??
            DateTime.now(),
      );
    }).toList();

    return GamificationHubPayload(
      streak: streak,
      achievements: achievements,
      leaderboardEntries: leaderboardEntries,
      availableQuizzes: availableQuizzes,
      dailyMissions: dailyMissions,
      teamChallenge: teamChallenge,
      xpProgress: xpProgress,
      nextBadgeProgress: nextBadgeProgress,
      badges: badges,
      studentBadges: studentBadges,
    );
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period) async {
    final normalized = period == 'monthly' ? 'monthly' : 'weekly';
    final raw = await _apiClient.get(
      '${ApiConstants.gamificationLeaderboardXp}?period=$normalized&limit=20',
    );
    final rows = (raw['entries'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    return rows.map((e) {
      final user = e['student'] as Map<String, dynamic>?;
      final firstName = (user?['firstName'] ?? '').toString();
      final lastName = (user?['lastName'] ?? '').toString();
      final displayName = ('$firstName $lastName').trim();
      return LeaderboardEntry(
        studentId: (e['userId'] ?? '').toString(),
        studentName: displayName.isEmpty ? 'Student' : displayName,
        rank: _asInt(e['rank'], fallback: 0),
        points: _asInt(e['points'], fallback: 0),
        scope: LeaderboardScope.classScope,
        period: normalized == 'monthly'
            ? LeaderboardPeriod.monthly
            : LeaderboardPeriod.weekly,
      );
    }).toList();
  }

  @override
  Future<List<AchievementModel>> fetchAchievements() async {
    final rows = await _apiClient.getList(
      ApiConstants.gamificationMyAchievementsProgress,
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map((json) => AchievementModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyMissionModel>> fetchDailyMissions() async {
    final rows = await _apiClient.getList(ApiConstants.gamificationMissions);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => DailyMissionModel(
            id: (m['id'] ?? '').toString(),
            title: (m['title'] ?? 'Mission').toString(),
            description: (m['description'] ?? '').toString(),
            xpReward: _asInt(m['xpReward'], fallback: 0),
            isCompleted: m['isCompleted'] == true,
            progressCurrent: _asInt(m['progressCurrent'], fallback: 0),
            progressTarget: _asInt(m['progressTarget'], fallback: 1),
          ),
        )
        .toList();
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
                DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<XpProgressModel> fetchXpProgress() async {
    final raw = await _apiClient.get(ApiConstants.gamificationMyProgress);
    final totalXp = _asInt(raw['totalXp'], fallback: 0);
    final level = _asInt(raw['level'], fallback: (totalXp ~/ 100).clamp(1, 999));
    return XpProgressModel(
      level: level,
      totalXp: totalXp,
      xpIntoCurrentLevel:
          _asInt(raw['xpIntoCurrentLevel'], fallback: totalXp % 100),
      xpNeededForNextLevel:
          _asInt(raw['xpNeededForNextLevel'], fallback: 100),
      weeklyXpTarget: _asInt(raw['weeklyXpTarget'], fallback: 300),
      weeklyXpEarned: _asInt(raw['weeklyXpEarned'], fallback: 0),
    );
  }

  @override
  Future<NextBadgeProgressModel?> fetchNextBadgeProgress() async {
    try {
      final rows = await _apiClient.getList(
        ApiConstants.gamificationMyAchievementsProgress,
      );
      final all = rows
          .whereType<Map<String, dynamic>>()
          .map((json) => AchievementModel.fromJson(json))
          .toList();
      final pending = all.where((a) => !a.isUnlocked).toList();
      if (pending.isEmpty) return null;
      final next = pending.first;
      return NextBadgeProgressModel(
        badgeName: next.title,
        description: next.description,
        progressCurrent: next.progressCurrent,
        progressTarget: next.progressTarget,
        xpReward: next.xpValue,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ExamModel> fetchQuiz(String subjectId) async {
    final quizzes = await fetchAvailableQuizzes();
    final match = quizzes.firstWhere(
      (q) => q.subjectId == subjectId,
      orElse: () => const QuizModel(
        id: '',
        title: '',
        subjectId: '',
        subjectName: '',
        questionCount: 0,
        xpReward: 0,
        difficulty: 'medium',
      ),
    );
    if (match.id.isEmpty) {
      throw Exception('Quiz not found');
    }
    final raw = await _apiClient.get(
      ApiConstants.gamificationQuizById(match.id),
    );
    return _mapExam(raw);
  }

  @override
  Future<ExamResultModel> submitQuizAnswers(
    String quizId,
    Map<String, int> answers,
  ) async {
    final raw = await _apiClient.post(
      ApiConstants.gamificationQuizSubmit(quizId),
      data: {'answers': answers},
    );
    final resultRaw = (raw['result'] is Map<String, dynamic>)
        ? raw['result'] as Map<String, dynamic>
        : raw;
    final mutationRaw = (raw['mutation'] is Map<String, dynamic>)
        ? raw['mutation'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final result = ExamResultModel(
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

    final mutation = _mapMutation(mutationRaw);
    _quizMutationCache[quizId] = mutation;
    return result;
  }

  @override
  Future<GamificationMutationResult> markMissionCompleted(
    String missionId,
  ) async {
    final raw = await _apiClient.post(
      ApiConstants.gamificationMissionComplete(missionId),
    );
    return _mapMutation(raw);
  }

  @override
  Future<GamificationMutationResult> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required ExamResultModel result,
  }) async {
    final mutation = _quizMutationCache[quizId];
    if (mutation == null) return GamificationMutationResult.empty;
    _quizMutationCache.remove(quizId);
    return mutation;
  }

  @override
  Future<StreakModel> fetchStreak() async {
    final raw = await _apiClient.get(ApiConstants.gamificationMyStreak);
    final currentStreak = _asInt(raw['currentStreak'], fallback: 0);
    final longestStreak = _asInt(raw['longestStreak'], fallback: 0);
    final lastLoginDateStr = (raw['lastLoginDate'] ?? '').toString();

    // Derive a synthetic recent-days list from lastLoginDate + currentStreak.
    // This is an approximation: we show the last N consecutive days ending at
    // lastLoginDate. Non-consecutive streaks will look consecutive here, but
    // this is acceptable client-side UX without a dedicated history endpoint.
    final recentDays = <DateTime>[];
    if (currentStreak > 0 && lastLoginDateStr.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastLoginDateStr);
      if (lastDate != null) {
        final count = currentStreak.clamp(1, 7);
        for (var i = count - 1; i >= 0; i--) {
          recentDays.add(lastDate.subtract(Duration(days: i)));
        }
      }
    }

    return StreakModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      recentDays: recentDays,
    );
  }

  @override
  Future<List<QuizModel>> fetchAvailableQuizzes() async {
    final rows = await _apiClient.getList(ApiConstants.gamificationQuizzes);
    return rows
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
  }

  @override
  Future<List<BadgeModel>> fetchBadges() async {
    final rows = await _apiClient.getList(ApiConstants.gamificationBadges);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (b) => BadgeModel(
            id: (b['id'] ?? '').toString(),
            key: (b['key'] ?? '').toString(),
            name: (b['name'] ?? 'Badge').toString(),
            description: (b['description'] ?? '').toString(),
            iconUrl: (b['iconKey'] ?? 'badge').toString(),
            iconKey: (b['iconKey'] ?? '').toString(),
            xpValue: _asInt(b['pointsValue'], fallback: 0),
          ),
        )
        .toList();
  }

  @override
  Future<List<StudentBadgeModel>> fetchStudentBadges(String studentId) async {
    final rows = await _apiClient.getList(ApiConstants.gamificationMyBadges);
    return rows.whereType<Map<String, dynamic>>().map((row) {
      final badgeRaw =
          (row['badge'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
      return StudentBadgeModel(
        studentId: (row['userId'] ?? row['studentId'] ?? 'me').toString(),
        badge: BadgeModel(
          id: (badgeRaw['id'] ?? '').toString(),
          key: (badgeRaw['key'] ?? '').toString(),
          name: (badgeRaw['name'] ?? 'Badge').toString(),
          description: (badgeRaw['description'] ?? '').toString(),
          iconUrl: (badgeRaw['iconKey'] ?? 'badge').toString(),
          iconKey: (badgeRaw['iconKey'] ?? '').toString(),
          xpValue: _asInt(badgeRaw['pointsValue'], fallback: 0),
        ),
        awardedAt:
            DateTime.tryParse((row['awardedAt'] ?? '').toString()) ??
                DateTime.now(),
      );
    }).toList();
  }

  ExamModel _mapExam(Map<String, dynamic> raw) {
    final questionRows = (raw['questions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final questions = questionRows.map((q) {
      final options = (q['options'] as List? ?? const [])
          .map((o) => o.toString())
          .toList();
      final typeRaw = (q['type'] ?? 'multipleChoice').toString();
      final type = QuestionType.values.firstWhere(
        (t) => t.name == typeRaw,
        orElse: () => QuestionType.multipleChoice,
      );
      return QuestionModel(
        id: (q['id'] ?? '').toString(),
        text: (q['text'] ?? '').toString(),
        options: options,
        correctIndex: _asInt(q['correctIndex'], fallback: 0),
        pointValue: _asDouble(q['pointValue'], fallback: 1),
        type: type,
      );
    }).toList();

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
