import 'package:dio/dio.dart';

import '../../exams/models/exam_model.dart';
import '../models/gamification_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import 'student_gamification_repository.dart';

class RealStudentGamificationRepository
    implements StudentGamificationRepository {
  final ApiClient _apiClient;
  final StorageService _storage;
  final LocalCacheService _cacheService;
  static final Map<String, GamificationMutationResult> _quizMutationCache = {};

  RealStudentGamificationRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _apiClient = apiClient ?? sl<ApiClient>(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<GamificationHubPayload> fetchHub() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'hub_payload');

    try {
      final raw = await _apiClient.get(ApiConstants.gamificationHub);
      final payload = _parseHubPayload(raw);
      // Cache individual parts so non-hub callers still get warm data.
      await _writeHubCachePartials(userId, raw);
      await _writeObject(cacheKey, raw);
      return payload;
    } catch (e) {
      // Network or 404 (older backend without BFF) → fall back to parallel
      // individual fetches so the screen still renders.
      try {
        final results = await Future.wait([
          fetchStreak(),
          fetchAchievements(),
          fetchLeaderboard('weekly'),
          fetchAvailableQuizzes(),
          fetchDailyMissions(),
          fetchTeamChallenge(),
          fetchXpProgress(),
          fetchNextBadgeProgress(),
          fetchBadges(),
          fetchStudentBadges(userId),
        ]);
        return GamificationHubPayload(
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
        );
      } catch (_) {
        // Last-resort: return whatever cached hub we have, else rethrow.
        final cached = _readObject(cacheKey, (j) => j);
        if (cached != null) return _parseHubPayload(cached);
        rethrow;
      }
    }
  }

  /// Parse the single BFF payload shape produced by
  /// `GamificationHubService.getHub` on the backend.
  GamificationHubPayload _parseHubPayload(Map<String, dynamic> raw) {
    // ── streak
    final streakRaw =
        (raw['streak'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final streak = StreakModel(
      currentStreak: _asInt(streakRaw['currentStreak'], fallback: 0),
      longestStreak: _asInt(streakRaw['longestStreak'], fallback: 0),
      recentDays: (streakRaw['recentDays'] as List? ?? const [])
          .map((d) => DateTime.tryParse(d.toString()))
          .whereType<DateTime>()
          .toList(),
    );

    // ── achievements
    final achievements = (raw['achievements'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AchievementModel.fromJson)
        .toList();

    // ── leaderboard
    final lbRaw =
        (raw['leaderboard'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final period = (lbRaw['period'] ?? 'weekly').toString();
    final leaderboardEntries = (lbRaw['entries'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) {
          final user = e['student'] as Map<String, dynamic>?;
          final firstName = (user?['firstName'] ?? '').toString();
          final lastName = (user?['lastName'] ?? '').toString();
          final displayName = ('$firstName $lastName').trim();
          return LeaderboardEntry(
            studentId: (e['userId'] ?? '').toString(),
            studentName: displayName.isEmpty ? 'Student' : displayName,
            rank: _asInt(e['rank'], fallback: 0),
            points: _asInt(e['points'], fallback: 0),
            scope: LeaderboardScope.school,
            period: period == 'monthly'
                ? LeaderboardPeriod.monthly
                : LeaderboardPeriod.weekly,
          );
        })
        .toList();

    // ── quizzes
    final availableQuizzes = (raw['availableQuizzes'] as List? ?? const [])
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

    // ── daily missions
    final dailyMissions = (raw['dailyMissions'] as List? ?? const [])
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

    // ── team challenge
    final tcRaw = raw['teamChallenge'] as Map<String, dynamic>?;
    final teamChallenge = tcRaw == null
        ? null
        : TeamChallengeModel(
            id: (tcRaw['id'] ?? '').toString(),
            title: (tcRaw['title'] ?? 'Team Challenge').toString(),
            objective: (tcRaw['objective'] ?? '').toString(),
            progressCurrent: _asInt(tcRaw['progressCurrent'], fallback: 0),
            progressTarget: _asInt(tcRaw['progressTarget'], fallback: 1),
            contributorCount: _asInt(tcRaw['contributorCount'], fallback: 0),
            endsAt: DateTime.tryParse((tcRaw['endsAt'] ?? '').toString()) ??
                DateTime.now(),
          );

    // ── xp progress
    final xpRaw =
        (raw['xpProgress'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final totalXp = _asInt(xpRaw['totalXp'], fallback: 0);
    final xpProgress = XpProgressModel(
      level: _asInt(xpRaw['level'], fallback: (totalXp ~/ 100).clamp(1, 999)),
      totalXp: totalXp,
      xpIntoCurrentLevel:
          _asInt(xpRaw['xpIntoCurrentLevel'], fallback: totalXp % 100),
      xpNeededForNextLevel:
          _asInt(xpRaw['xpNeededForNextLevel'], fallback: 100),
      weeklyXpTarget: _asInt(xpRaw['weeklyXpTarget'], fallback: 300),
      weeklyXpEarned: _asInt(xpRaw['weeklyXpEarned'], fallback: 0),
    );

    // ── next badge progress
    final nbRaw = raw['nextBadgeProgress'] as Map<String, dynamic>?;
    final nextBadgeProgress = nbRaw == null
        ? null
        : NextBadgeProgressModel(
            badgeName: (nbRaw['badgeName'] ?? nbRaw['title'] ?? 'Next Badge')
                .toString(),
            description: (nbRaw['description'] ?? '').toString(),
            progressCurrent: _asInt(nbRaw['progressCurrent'], fallback: 0),
            progressTarget: _asInt(nbRaw['progressTarget'], fallback: 1),
            xpReward: _asInt(nbRaw['xpReward'] ?? nbRaw['xpValue'], fallback: 0),
          );

    // ── badges (filter synthetic per-day reward badges)
    final badges = (raw['badges'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((b) => !_isSyntheticBadgeKey((b['key'] ?? '').toString()))
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

    // ── student badges (also filter synthetic)
    final studentBadges = (raw['studentBadges'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((row) {
          final badgeRaw =
              (row['badge'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
          return !_isSyntheticBadgeKey((badgeRaw['key'] ?? '').toString());
        })
        .map((row) {
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
            awardedAt:
                DateTime.tryParse((row['awardedAt'] ?? '').toString()) ??
                    DateTime.now(),
          );
        })
        .toList();

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

  /// Hide auto-generated quiz/mission reward badges from the global galleries —
  /// they're an internal XP plumbing detail, not real collectables.
  bool _isSyntheticBadgeKey(String key) {
    return key.startsWith('quiz_reward_') || key.startsWith('mission_');
  }

  /// Persist hub sub-blocks into the same cache slots that the individual
  /// fetchers use, so refreshing one section after a mutation still works
  /// even before the next hub call.
  Future<void> _writeHubCachePartials(
    String userId,
    Map<String, dynamic> raw,
  ) async {
    Future<void> writeIf(String suffix, dynamic value) async {
      if (value == null) return;
      await _cacheService.write(_cacheKey(userId, suffix), value);
    }

    await writeIf('streak', raw['streak']);
    await writeIf('xp_progress', raw['xpProgress']);
    await writeIf('team_challenge', raw['teamChallenge']);
    if (raw['achievements'] is List) {
      await writeIf('achievements', raw['achievements']);
    }
    if (raw['dailyMissions'] is List) {
      await writeIf('missions', raw['dailyMissions']);
    }
    if (raw['availableQuizzes'] is List) {
      await writeIf('quizzes', raw['availableQuizzes']);
    }
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period, {int offset = 0, int limit = 20}) async {
    final normalized = period == 'monthly' ? 'monthly' : 'weekly';
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'leaderboard_$normalized');
    final cached = _readList(cacheKey, LeaderboardEntry.fromJson);
    
    // Only use cache for initial load, bypass for pagination
    if (offset == 0 && cached != null && cached.isNotEmpty) {
       // We'll still fetch fresh below, but maybe we can just return cache if we had a TTL check.
       // Let's just proceed to fetch and cache.
    }
    
    try {
      final raw = await _apiClient.get(
        '${ApiConstants.gamificationLeaderboardXp}?period=$normalized&offset=$offset&limit=$limit',
      );
      final rows = (raw['entries'] as List? ?? const [])
          .whereType<Map<String, dynamic>>();
      final entries = rows.map((e) {
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
      await _writeList(cacheKey, entries);
      return entries;
    } catch (e) {
      if (e is DioException && cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<AchievementModel>> fetchAchievements() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'achievements');
    final cached = _readList(cacheKey, AchievementModel.fromJson);
    try {
      final rows = await _apiClient.getList(
        ApiConstants.gamificationMyAchievementsProgress,
      );
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((json) => AchievementModel.fromJson(json))
          .toList();
      await _writeList(cacheKey, items);
      return items;
    } catch (e) {
      if (e is DioException && cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<DailyMissionModel>> fetchDailyMissions() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'missions');
    final cached = _readList(cacheKey, DailyMissionModel.fromJson);
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationMissions);
      final items = rows
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
      await _writeList(cacheKey, items);
      return items;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<TeamChallengeModel?> fetchTeamChallenge() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'team_challenge');
    final cached = _readObject(cacheKey, TeamChallengeModel.fromJson);
    try {
      final raw = await _apiClient.get(ApiConstants.gamificationTeamChallenge);
      final model = TeamChallengeModel(
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
      await _writeObject(cacheKey, model.toJson());
      return model;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<XpProgressModel> fetchXpProgress() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'xp_progress');
    final cached = _readObject(cacheKey, XpProgressModel.fromJson);
    try {
      final raw = await _apiClient.get(ApiConstants.gamificationMyProgress);
      final totalXp = _asInt(raw['totalXp'], fallback: 0);
      final level =
          _asInt(raw['level'], fallback: (totalXp ~/ 100).clamp(1, 999));
      final model = XpProgressModel(
        level: level,
        totalXp: totalXp,
        xpIntoCurrentLevel:
            _asInt(raw['xpIntoCurrentLevel'], fallback: totalXp % 100),
        xpNeededForNextLevel:
            _asInt(raw['xpNeededForNextLevel'], fallback: 100),
        weeklyXpTarget: _asInt(raw['weeklyXpTarget'], fallback: 300),
        weeklyXpEarned: _asInt(raw['weeklyXpEarned'], fallback: 0),
      );
      await _writeObject(cacheKey, model.toJson());
      return model;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<NextBadgeProgressModel?> fetchNextBadgeProgress() async {
    return null;
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
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'quiz_${match.id}');
    final cached = _readObject(cacheKey, ExamModel.fromJson);
    try {
      final raw = await _apiClient.get(
        ApiConstants.gamificationQuizById(match.id),
      );
      final model = _mapExam(raw);
      await _writeObject(cacheKey, model.toJson());
      return model;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
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
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'streak');
    final cached = _readObject(cacheKey, StreakModel.fromJson);
    try {
      final raw = await _apiClient.get(ApiConstants.gamificationMyStreak);
      final model = StreakModel(
        currentStreak: _asInt(raw['currentStreak'], fallback: 0),
        longestStreak: _asInt(raw['longestStreak'], fallback: 0),
        recentDays: const [],
      );
      await _writeObject(cacheKey, model.toJson());
      return model;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<QuizModel>> fetchAvailableQuizzes() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'quizzes');
    final cached = _readList(cacheKey, QuizModel.fromJson);
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationQuizzes);
      final items = rows
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
      await _writeList(cacheKey, items);
      return items;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<BadgeModel>> fetchBadges() async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, 'badges');
    final cached = _readList(cacheKey, BadgeModel.fromJson);
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationBadges);
      final items = rows
          .whereType<Map<String, dynamic>>()
          .where((b) => !_isSyntheticBadgeKey((b['key'] ?? '').toString()))
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
      await _writeList(cacheKey, items);
      return items;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<StudentBadgeModel>> fetchStudentBadges(String studentId) async {
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(
      userId,
      'student_badges_${studentId.isEmpty ? 'me' : studentId}',
    );
    final cached = _readList(cacheKey, StudentBadgeModel.fromJson);
    try {
      final rows = await _apiClient.getList(ApiConstants.gamificationMyBadges);
      final items = rows
          .whereType<Map<String, dynamic>>()
          .where((row) {
            final badgeRaw =
                (row['badge'] as Map<String, dynamic>?) ??
                    const <String, dynamic>{};
            return !_isSyntheticBadgeKey((badgeRaw['key'] ?? '').toString());
          })
          .map((row) {
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
      await _writeList(cacheKey, items);
      return items;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
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

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId, String suffix) {
    if (userId.isEmpty) return 'student_gamification_$suffix';
    return 'student_gamification_${userId}_$suffix';
  }

  List<T>? _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? maxAge,
  }) {
    final entry = _cacheService.read(key, maxAge: maxAge);
    if (entry == null || entry.data is! List) return null;
    return (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  T? _readObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? maxAge,
  }) {
    final entry = _cacheService.read(key, maxAge: maxAge);
    if (entry == null || entry.data is! Map<String, dynamic>) return null;
    return fromJson(Map<String, dynamic>.from(entry.data as Map));
  }

  Future<void> _writeList<T>(String key, List<T> items) async {
    await _cacheService.write(
      key,
      items.map((item) => (item as dynamic).toJson()).toList(),
    );
  }

  Future<void> _writeObject(String key, Map<String, dynamic> value) async {
    await _cacheService.write(key, value);
  }
}
