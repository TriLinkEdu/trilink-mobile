import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/curriculum_models.dart';
import 'student_curriculum_repository.dart';

class RealStudentCurriculumRepository implements StudentCurriculumRepository {
  final ApiClient _api;
  final StudentCurriculumRepository _fallback;

  static const Duration _subjectsTtl = Duration(seconds: 30);
  static const Duration _topicsTtl = Duration(seconds: 30);

  static List<SubjectModel>? _subjectsCache;
  static DateTime? _subjectsFetchedAt;
  static Future<List<SubjectModel>>? _subjectsInFlight;

  static final Map<String, List<TopicModel>> _topicsCache =
      <String, List<TopicModel>>{};
  static final Map<String, DateTime> _topicsFetchedAt = <String, DateTime>{};
  static final Map<String, Future<List<TopicModel>>> _topicsInFlight =
      <String, Future<List<TopicModel>>>{};

  RealStudentCurriculumRepository({
    ApiClient? apiClient,
    required StudentCurriculumRepository fallback,
  }) : _api = apiClient ?? ApiClient(),
       _fallback = fallback;

  @override
  Future<List<SubjectModel>> fetchSubjects() async {
    if (_subjectsCache != null && _subjectsFetchedAt != null) {
      final age = DateTime.now().difference(_subjectsFetchedAt!);
      if (age < _subjectsTtl) return _subjectsCache!;
    }

    final inFlight = _subjectsInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchSubjectsFresh();
    _subjectsInFlight = future;
    final data = await future;
    _subjectsInFlight = null;
    _subjectsCache = data;
    _subjectsFetchedAt = DateTime.now();
    return data;
  }

  Future<List<SubjectModel>> _fetchSubjectsFresh() async {
    try {
      final rows = await _api.getList(ApiConstants.curriculumSubjects);
      if (rows.isEmpty) return _fallback.fetchSubjects();
      return rows
          .whereType<Map<String, dynamic>>()
          .map(SubjectModel.fromJson)
          .toList();
    } catch (_) {
      return _fallback.fetchSubjects();
    }
  }

  @override
  Future<List<TopicModel>> fetchTopics(String subjectId) async {
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
    final data = await future;
    _topicsInFlight.remove(subjectId);
    _topicsCache[subjectId] = data;
    _topicsFetchedAt[subjectId] = DateTime.now();
    return data;
  }

  Future<List<TopicModel>> _fetchTopicsFresh(String subjectId) async {
    try {
      final rows = await _api.getList(ApiConstants.curriculumTopics(subjectId));
      if (rows.isEmpty) return _fallback.fetchTopics(subjectId);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(TopicModel.fromJson)
          .toList();
    } catch (_) {
      return _fallback.fetchTopics(subjectId);
    }
  }
}
