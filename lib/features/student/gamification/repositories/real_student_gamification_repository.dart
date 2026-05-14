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
      _currentUserId().then((id) => fetchStudentBadges(id)),
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
    } catch (_) {
      if (cached != null) return cached;
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
    } catch (_) {
      if (cached != null) return cached;
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
      final items = rows.whereType<Map<String, dynamic>>().map((row) {
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
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final entry = _cacheService.read(key);
    if (entry == null || entry.data is! List) return null;
    return (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  T? _readObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final entry = _cacheService.read(key);
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
