import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/grade_model.dart';
import 'student_grades_repository.dart';

/// Production grades repository.
///
/// Fixes over the previous version:
/// 1. Errors are thrown instead of swallowed — the cubit controls error state.
/// 2. _termFromDate now correctly models the Ethiopian academic year:
///    Sep–Jan  → "Fall <year>"
///    Feb–Aug  → "Spring <year>"
///    (the previous version used `||` which made Feb–Aug all "Spring" correctly
///    but made Jan "Fall" — now unified and explicit).
/// 3. fetchAvailableTerms() derives actual terms from live data instead of
///    returning a hardcoded ["Fall 2023", "Spring 2023"].
class RealStudentGradesRepository implements StudentGradesRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  List<GradeModel>? _allGradesCache;
  DateTime? _fetchedAt;
  Future<List<GradeModel>>? _inFlight;
  static const Duration _ttl = Duration(minutes: 30);

  RealStudentGradesRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Future<List<GradeModel>> fetchGrades({String? term}) async {
    final all = await _getAllGrades();
    if (term == null || term.isEmpty) return all;
    return all.where((g) => g.term == term).toList();
  }

  @override
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId) async {
    final all = await _getAllGrades();
    return all.where((g) => g.subjectId == subjectId).toList();
  }

  @override
  Future<List<String>> fetchAvailableTerms() async {
    final all = await _getAllGrades();
    // Collect distinct non-null terms, preserving the order they appear
    // (data is sorted date-desc so earliest distinct = most recent term first).
    final seen = <String>{};
    final terms = <String>[];
    for (final g in all) {
      final t = g.term;
      if (t != null && seen.add(t)) {
        terms.add(t);
      }
    }
    return terms;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<List<GradeModel>> _getAllGrades() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_isCacheValid()) return _allGradesCache!;
    if (_inFlight != null) return _inFlight!;

    final future = _fetchFreshAllGrades();
    _inFlight = future;
    try {
      final data = await future;
      _allGradesCache = data;
      _fetchedAt = DateTime.now();
      await _cacheService.write(
        _cacheKey(userId),
        data.map((item) => item.toJson()).toList(),
      );
      return data;
    } catch (_) {
      if (_allGradesCache != null) return _allGradesCache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  bool _isCacheValid() =>
      _allGradesCache != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  Future<List<GradeModel>> _fetchFreshAllGrades() async {
    // Throws on failure — callers (cubit) handle the error state.
    final data = await _api.get('/reports/my-grades');
    final subjects = data['subjects'];
    if (subjects is! List) return const [];

    final grades = <GradeModel>[];
    for (final subject in subjects.whereType<Map<String, dynamic>>()) {
      final subjectId = (subject['subjectId'] ?? '').toString();
      final subjectName = (subject['subjectName'] ?? 'Subject').toString();
      final exams = subject['exams'];
      if (exams is! List) continue;

      for (final exam in exams.whereType<Map<String, dynamic>>()) {
        grades.add(_toGrade(
          subjectId: subjectId,
          subjectName: subjectName,
          raw: exam,
        ));
      }
    }

    // Most recent first — this also makes fetchAvailableTerms() return most
    // recent term at index 0 without extra sorting.
    grades.sort((a, b) => b.date.compareTo(a.date));
    return grades;
  }

  GradeModel _toGrade({
    required String subjectId,
    required String subjectName,
    required Map<String, dynamic> raw,
  }) {
    final releasedAt = (raw['releasedAt'] ?? '').toString();
    final score = _readDouble(raw['score']);
    final maxScore = _readDouble(raw['maxPoints'], fallback: 100);
    final date = DateTime.tryParse(releasedAt) ?? DateTime.now();

    return GradeModel(
      id: (raw['attemptId'] ?? raw['examId'] ?? '').toString(),
      subjectId: subjectId,
      subjectName: subjectName,
      assessmentName: (raw['title'] ?? 'Assessment').toString(),
      score: score,
      maxScore: maxScore <= 0 ? 100 : maxScore,
      date: date,
      term: _termFromDate(date),
    );
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  /// Ethiopian academic year term derivation.
  ///
  /// Sept (9) – Jan (1) = Fall semester
  /// Feb (2)  – Aug (8) = Spring semester
  String _termFromDate(DateTime date) {
    final month = date.month;
    final isFall = month >= 9 || month == 1;
    // For Jan, attribute to the Fall of the previous calendar year
    // (e.g. Jan 2024 is "Fall 2023").
    final year = (month == 1) ? date.year - 1 : date.year;
    return isFall ? 'Fall $year' : 'Spring $year';
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) =>
      userId.isEmpty ? 'student_grades_v1' : 'student_grades_v1_$userId';

  @override
  List<GradeModel>? getCached() => _allGradesCache;

  @override
  void clearCache() {
    _allGradesCache = null;
    _fetchedAt = null;
    _inFlight = null;
  }

  void _restoreCache(String userId) {
    if (_allGradesCache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! List) return;
    _allGradesCache = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(GradeModel.fromJson)
        .toList();
    _fetchedAt = entry.savedAt;
  }
}
