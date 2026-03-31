import '../models/ai_assistant_models.dart';
import 'student_ai_assistant_repository.dart';

class MockStudentAiAssistantRepository implements StudentAiAssistantRepository {
  static const Duration _latency = Duration(milliseconds: 320);

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
