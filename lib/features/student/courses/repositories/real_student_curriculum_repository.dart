import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/curriculum_models.dart';
import '../../../../core/services/local_cache_service.dart';
import 'student_curriculum_repository.dart';

class RealStudentCurriculumRepository implements StudentCurriculumRepository {
  final ApiClient _api;
  final LocalCacheService _cache;

  static const Duration _subjectsTtl = Duration(minutes: 30);
  static const Duration _topicsTtl = Duration(minutes: 30);

  List<SubjectModel>? _subjectsCache;
  DateTime? _subjectsFetchedAt;
  Future<List<SubjectModel>>? _subjectsInFlight;

  final Map<String, List<TopicModel>> _topicsCache =
      <String, List<TopicModel>>{};
  final Map<String, DateTime> _topicsFetchedAt = <String, DateTime>{};
  final Map<String, Future<List<TopicModel>>> _topicsInFlight =
      <String, Future<List<TopicModel>>>{};

  RealStudentCurriculumRepository({
    ApiClient? apiClient,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _cache = cacheService;

  @override
  Future<List<SubjectModel>> fetchSubjects() async {
    _restoreSubjectsCache();
    if (_subjectsCache != null && _subjectsFetchedAt != null) {
      final age = DateTime.now().difference(_subjectsFetchedAt!);
      if (age < _subjectsTtl) return _subjectsCache!;
    }

    final inFlight = _subjectsInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchSubjectsFresh();
    _subjectsInFlight = future;
    try {
      final data = await future;
      _subjectsCache = data;
      _subjectsFetchedAt = DateTime.now();
      return data;
    } catch (_) {
      if (_subjectsCache != null) return _subjectsCache!;
      rethrow;
    } finally {
      _subjectsInFlight = null;
    }
  }

  Future<List<SubjectModel>> _fetchSubjectsFresh() async {
    final rows = await _api.getList(ApiConstants.curriculumSubjects);
    final subjects = rows
        .whereType<Map<String, dynamic>>()
        .map(SubjectModel.fromJson)
        .toList();
    await _cache.write(
      _subjectsCacheKey,
      subjects.map((item) => item.toJson()).toList(),
    );
    return subjects;
  }

  @override
  Future<List<TopicModel>> fetchTopics(String subjectId) async {
    _restoreTopicsCache(subjectId);
    final cached = _topicsCache[subjectId];
    final fetchedAt = _topicsFetchedAt[subjectId];
    if (cached != null && fetchedAt != null) {
      final age = DateTime.now().difference(fetchedAt);
      if (age < _topicsTtl) return cached;
    }

    final inFlight = _topicsInFlight[subjectId];
    if (inFlight != null) return inFlight;

    final future = _fetchTopicsFresh(subjectId);
    _topicsInFlight[subjectId] = future;
    try {
      final data = await future;
      _topicsCache[subjectId] = data;
      _topicsFetchedAt[subjectId] = DateTime.now();
      return data;
    } catch (_) {
      final cachedFallback = _topicsCache[subjectId];
      if (cachedFallback != null) return cachedFallback;
      rethrow;
    } finally {
      _topicsInFlight.remove(subjectId);
    }
  }

  Future<List<TopicModel>> _fetchTopicsFresh(String subjectId) async {
    final rows = await _api.getList(ApiConstants.curriculumTopics(subjectId));
    final topics = rows
        .whereType<Map<String, dynamic>>()
        .map(TopicModel.fromJson)
        .toList();
    await _cache.write(
      _topicsCacheKey(subjectId),
      topics.map((item) => item.toJson()).toList(),
    );
    return topics;
  }

  static const String _subjectsCacheKey = 'student_curriculum_subjects_v1';

  static String _topicsCacheKey(String subjectId) =>
      'student_curriculum_topics_v1_$subjectId';

  void _restoreSubjectsCache() {
    if (_subjectsCache != null) return;
    final entry = _cache.read(_subjectsCacheKey);
    if (entry == null) return;
    final cached = _decodeSubjects(entry.data);
    if (cached == null) return;
    _subjectsCache = cached;
    _subjectsFetchedAt = entry.savedAt;
  }

  void _restoreTopicsCache(String subjectId) {
    if (_topicsCache.containsKey(subjectId)) return;
    final entry = _cache.read(_topicsCacheKey(subjectId));
    if (entry == null) return;
    final cached = _decodeTopics(entry.data);
    if (cached == null) return;
    _topicsCache[subjectId] = cached;
    _topicsFetchedAt[subjectId] = entry.savedAt;
  }

  List<SubjectModel>? _decodeSubjects(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SubjectModel.fromJson)
        .toList();
  }

  List<TopicModel>? _decodeTopics(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TopicModel.fromJson)
        .toList();
  }

  @override
  List<SubjectModel>? getCached() => _subjectsCache;

  @override
  void clearCache() {
    _subjectsCache = null;
    _subjectsFetchedAt = null;
    _subjectsInFlight = null;
    _topicsCache.clear();
    _topicsFetchedAt.clear();
    _topicsInFlight.clear();
  }
}
