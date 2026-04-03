import '../models/ai_assistant_models.dart';
import 'student_ai_assistant_repository.dart';

class MockStudentAiAssistantRepository implements StudentAiAssistantRepository {
  static const Duration _latency = Duration(milliseconds: 320);

  @override
  Future<String> getAiResponse(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final lower = message.toLowerCase();

    if (lower.contains('grade') || lower.contains('score')) {
      return 'Based on your recent performance, I recommend focusing on '
          'spaced repetition for weak topics. Try reviewing your lowest-scoring '
          'areas 15 minutes daily — consistency beats cramming every time!';
    }
    if (lower.contains('assignment') || lower.contains('homework')) {
      return 'Great question! Break your assignment into smaller chunks and '
          'tackle the hardest part first when your energy is highest. Set a '
          'timer for 25-minute focused sessions with 5-minute breaks.';
    }
    if (lower.contains('exam') || lower.contains('test')) {
      return 'Exam prep tip: Start with a practice test to identify gaps, '
          'then focus your study on those areas. Mix in active recall — '
          'close your notes and try to explain concepts out loud.';
    }
    return 'I\'m here to help with your studies! You can ask me about your '
        'grades, assignments, exam preparation, or any topic you\'re '
        'working on. What would you like to explore?';
  }

  @override
  Future<AiAssistantData> fetchAssistantData() async {
    await Future<void>.delayed(_latency);

    return const AiAssistantData(
      learningPath: [
        LearningPathItemModel(
          step: 1,
          title: 'Forces & Motion',
          subject: 'Physics',
          duration: '15 min',
          progress: 0.6,
          isActive: true,
        ),
        LearningPathItemModel(
          step: 2,
          title: "Newton's Laws",
          subject: 'Physics',
          duration: '20 min',
          progress: 0,
          isActive: false,
        ),
        LearningPathItemModel(
          step: 3,
          title: 'Friction & Gravity',
          subject: 'Physics',
          duration: '10 min',
          progress: 0,
          isActive: false,
        ),
      ],
      resources: [
        ResourceRecommendationModel(
          id: 'r1',
          title: 'Intro to Newtonian Mechanics',
          type: 'Video',
          estimatedTime: '12 min',
          level: 'Core',
        ),
        ResourceRecommendationModel(
          id: 'r2',
          title: 'Practice Set: Forces & Motion',
          type: 'Worksheet',
          estimatedTime: '20 min',
          level: 'Practice',
        ),
        ResourceRecommendationModel(
          id: 'r3',
          title: 'Exam Tips: Kinematics',
          type: 'Article',
          estimatedTime: '8 min',
          level: 'Revision',
        ),
      ],
      insights: [
        EvaluateInsightModel(
          title: 'Strength',
          summary: 'You consistently perform well in conceptual questions.',
          recommendation:
              'Keep using quick concept summaries before problem-solving.',
        ),
        EvaluateInsightModel(
          title: 'Focus Area',
          summary: 'Numerical questions with multiple steps reduce your speed.',
          recommendation:
              'Practice 3 timed multi-step problems daily for a week.',
        ),
      ],
    );
  }
}
