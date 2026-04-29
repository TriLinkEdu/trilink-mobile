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
          'areas 15 minutes daily   consistency beats cramming every time!';
    }
    if (lower.contains('assignment') || lower.contains('homework')) {
      return 'Great question! Break your assignment into smaller chunks and '
          'tackle the hardest part first when your energy is highest. Set a '
          'timer for 25-minute focused sessions with 5-minute breaks.';
    }
    if (lower.contains('exam') || lower.contains('test')) {
      return 'Exam prep tip: Start with a practice test to identify gaps, '
          'then focus your study on those areas. Mix in active recall   '
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
          topicId: 'topic1',
          topicName: 'Forces & Motion',
          currentMastery: 0.6,
          targetMastery: 0.8,
          sequenceOrder: 1,
          isCompleted: false,
          explanation: 'Start here',
        ),
        LearningPathItemModel(
          topicId: 'topic2',
          topicName: "Newton's Laws",
          currentMastery: 0.0,
          targetMastery: 0.8,
          sequenceOrder: 2,
          isCompleted: false,
          explanation: 'Next topic',
        ),
        LearningPathItemModel(
          topicId: 'topic3',
          topicName: 'Friction & Gravity',
          currentMastery: 0.0,
          targetMastery: 0.8,
          sequenceOrder: 3,
          isCompleted: false,
          explanation: 'Advanced topic',
        ),
      ],
      resources: [
        ResourceRecommendationModel(
          type: 'video',
          title: 'Intro to Newtonian Mechanics',
          url: 'https://www.khanacademy.org/science/physics/forces-newtons-laws',
          difficulty: 'medium',
          description: '12 min video',
        ),
        ResourceRecommendationModel(
          type: 'worksheet',
          title: 'Practice Set: Forces & Motion',
          url: 'https://example.com/resources/forces-motion-practice.pdf',
          difficulty: 'medium',
          description: '20 min practice',
        ),
        ResourceRecommendationModel(
          type: 'article',
          title: 'Exam Tips: Kinematics',
          url: 'https://example.com/articles/kinematics-exam-tips',
          difficulty: 'easy',
          description: '8 min read',
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
