import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/local_cache_service.dart';
import '../models/ai_assistant_models.dart';
import 'student_ai_assistant_repository.dart';

class RealStudentAiAssistantRepository implements StudentAiAssistantRepository {
  final ApiClient _api;
  final String _studentId;
  final LocalCacheService _cacheService;
  final int _gradeLevel;

  RealStudentAiAssistantRepository({
    ApiClient? apiClient,
    required String studentId,
    required LocalCacheService cacheService,
    int gradeLevel = 9,
  })  : _api = apiClient ?? ApiClient(),
        _studentId = studentId,
        _cacheService = cacheService,
        _gradeLevel = gradeLevel;

  @override
  Future<AiAssistantData> fetchAssistantData() async {
    final cached = _restoreCache();
    try {
      // Fetch all three in parallel
      final results = await Future.wait([
        _fetchLearningPath(),
        _fetchRecommendations(),
        _fetchEvaluate(),
      ]);

      final data = AiAssistantData(
        learningPath: results[0] as List<LearningPathItemModel>,
        resources: results[1] as List<ResourceRecommendationModel>,
        insights: results[2] as List<EvaluateInsightModel>,
      );
      await _cacheService.write(_cacheKey, data.toJson());
      return data;
    } catch (e) {
      if (cached != null) return cached;
      return const AiAssistantData(
        learningPath: [],
        resources: [],
        insights: [],
      );
    }
  }

  @override
  Future<AiChatMessage> getAiResponse(String message) async {
    try {
      final response = await _api.post(
        ApiConstants.aiChat,
        data: {
          'student_id': _studentId,
          'message': message,
          'grade_level': _gradeLevel,
        },
      );

      final answer = (response['answer'] as String?) ??
          'Sorry, I could not generate a response.';

      // Backend explicitly signals "AI not configured" — treat as a real error
      // so the UI can show a retry CTA instead of pretending it answered.
      if (answer.contains('not configured')) {
        throw Exception('AI service is not available. Please contact support.');
      }

      return AiChatMessage(
        text: answer,
        isUser: false,
        timestamp: DateTime.now(),
        sources: _extractSources(response['sources']),
      );
    } catch (e) {
      if (e.toString().contains('not configured')) rethrow;
      throw Exception('Failed to get AI response: ${e.toString()}');
    }
  }

  @override
  Future<List<AiChatMessage>> fetchChatHistory({int limit = 20}) async {
    try {
      final response = await _api.get(
        ApiConstants.aiChatHistory(_studentId),
        queryParameters: {'limit': limit.toString()},
      );

      final messages = (response['messages'] ?? response['history']) as List? ?? const [];
      final history = <AiChatMessage>[];
      for (final m in messages) {
        if (m is! Map<String, dynamic>) continue;
        final text = (m['message'] ?? m['content'] ?? '').toString();
        if (text.isEmpty) continue;
        final ts = DateTime.tryParse((m['timestamp'] ?? '').toString()) ??
            DateTime.now();
        history.add(
          AiChatMessage(
            text: text,
            isUser: (m['role'] ?? '') == 'user',
            timestamp: ts,
          ),
        );
      }
      // Server returns most-recent-first; flip so chat renders oldest-at-top.
      return history.reversed.toList();
    } catch (_) {
      return const [];
    }
  }

  /// Normalises the various shapes the backend may use for `sources`:
  ///   - `["title1", "title2"]`
  ///   - `[{title, topic_id, score}, ...]`
  ///   - `null` / missing
  List<AiChatSource>? _extractSources(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    final out = <AiChatSource>[];
    for (final item in raw) {
      if (item is String && item.trim().isNotEmpty) {
        out.add(AiChatSource(title: item.trim()));
      } else if (item is Map) {
        final title = (item['title'] ?? item['name'] ?? '').toString().trim();
        if (title.isNotEmpty) {
          out.add(AiChatSource(
            title: title,
            topicId: item['topic_id']?.toString(),
            score: item['score'] is num
                ? (item['score'] as num).toDouble()
                : null,
          ));
        }
      }
    }
    return out.isEmpty ? null : out;
  }

  Future<List<LearningPathItemModel>> _fetchLearningPath() async {
    try {
      final response = await _api.get(
        ApiConstants.aiLearningPath(_studentId),
      );
      
      // Check if it's stub data
      if (response['source'] == 'stub') {
        return [];
      }
      
      final topics = response['topics'] as List? ?? [];
      return topics
          .map((t) => LearningPathItemModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ResourceRecommendationModel>> _fetchRecommendations() async {
    try {
      final response = await _api.get(
        ApiConstants.aiRecommendations(_studentId),
        queryParameters: {'limit': '5'},
      );
      
      // Check if it's stub data
      if (response['source'] == 'stub') {
        return [];
      }
      
      final resources = response['resources'] as List? ?? [];
      return resources
          .map((r) => ResourceRecommendationModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<EvaluateInsightModel>> _fetchEvaluate() async {
    try {
      final response = await _api.get(
        ApiConstants.aiEvaluate(_studentId),
      );
      
      // Convert backend response to insights
      final insights = <EvaluateInsightModel>[];
      
      if (response['attendance'] != null) {
        final att = response['attendance'] as Map<String, dynamic>;
        insights.add(EvaluateInsightModel(
          title: 'Attendance',
          summary: '${att['rate']}% attendance rate',
          recommendation: att['status'] == 'good' 
              ? 'Keep up the great attendance!' 
              : 'Try to attend more classes',
        ));
      }
      
      if (response['performance'] != null) {
        final perf = response['performance'] as Map<String, dynamic>;
        insights.add(EvaluateInsightModel(
          title: 'Performance',
          summary: '${perf['average_score']}% average score',
          recommendation: perf['trend'] == 'improving' 
              ? 'Great progress!' 
              : 'Focus on weak areas',
        ));
      }
      
      if (response['engagement'] != null) {
        final eng = response['engagement'] as Map<String, dynamic>;
        insights.add(EvaluateInsightModel(
          title: 'Engagement',
          summary: '${eng['streak']} day streak',
          recommendation: 'Keep logging in daily!',
        ));
      }
      
      return insights;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateMastery({
    required String topicId,
    required bool isCorrect,
  }) async {
    await _api.post(
      ApiConstants.aiMasteryUpdate,
      data: {
        'student_id': _studentId,
        'topic_id': topicId,
        'is_correct': isCorrect,
      },
    );
  }

  Future<Map<String, dynamic>> getMastery(String topicId) async {
    return await _api.get(
      ApiConstants.aiMastery(_studentId, topicId),
    );
  }

  Future<List<Map<String, dynamic>>> getWeakTopics(String subjectId) async {
    final response = await _api.get(
      ApiConstants.aiWeakTopics(_studentId, subjectId),
    );
    return (response['weak_topics'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getNextQuestion(String topicId) async {
    return await _api.get(
      ApiConstants.aiNextQuestion(_studentId, topicId),
    );
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    return await _api.get(
      ApiConstants.aiWeeklySummary(_studentId),
    );
  }

  String get _cacheKey => 'student_ai_assistant_v1_$_studentId';

  AiAssistantData? _restoreCache() {
    final entry = _cacheService.read(_cacheKey);
    if (entry == null || entry.data is! Map<String, dynamic>) return null;
    return AiAssistantData.fromJson(
      Map<String, dynamic>.from(entry.data as Map),
    );
  }
}
