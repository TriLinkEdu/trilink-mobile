import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ai_assistant_models.dart';
import 'student_ai_assistant_repository.dart';

class RealStudentAiAssistantRepository implements StudentAiAssistantRepository {
  final ApiClient _api;
  final String _studentId;

  RealStudentAiAssistantRepository({
    ApiClient? apiClient,
    required String studentId,
  })  : _api = apiClient ?? ApiClient(),
        _studentId = studentId;

  @override
  Future<AiAssistantData> fetchAssistantData() async {
    try {
      // Fetch all three in parallel
      final results = await Future.wait([
        _fetchLearningPath(),
        _fetchRecommendations(),
        _fetchEvaluate(),
      ]);

      return AiAssistantData(
        learningPath: results[0] as List<LearningPathItemModel>,
        resources: results[1] as List<ResourceRecommendationModel>,
        insights: results[2] as List<EvaluateInsightModel>,
      );
    } catch (e) {
      // Return empty data on error
      return const AiAssistantData(
        learningPath: [],
        resources: [],
        insights: [],
      );
    }
  }

  @override
  Future<String> getAiResponse(String message) async {
    try {
      final response = await _api.post(
        ApiConstants.aiChat,
        body: {
          'student_id': _studentId,
          'message': message,
          'grade_level': 9,
        },
      );
      
      final answer = response['answer'] as String?;
      
      // Check if it's an error message
      if (answer != null && answer.contains('not configured')) {
        throw Exception('AI service is not available. Please contact support.');
      }
      
      return answer ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      if (e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Failed to get AI response: ${e.toString()}');
    }
  }

  Future<List<AiChatMessage>> getChatHistory({int limit = 20}) async {
    final response = await _api.get(
      ApiConstants.aiChatHistory(_studentId),
      queryParameters: {'limit': limit.toString()},
    );
    
    final messages = response['messages'] as List? ?? [];
    return messages.map((m) {
      final msg = m as Map<String, dynamic>;
      return AiChatMessage(
        text: msg['message'] as String,
        isUser: msg['role'] == 'user',
        timestamp: DateTime.parse(msg['timestamp'] as String),
      );
    }).toList();
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
      body: {
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
}
