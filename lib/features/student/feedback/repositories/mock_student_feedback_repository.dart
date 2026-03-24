import '../models/feedback_model.dart';
import 'student_feedback_repository.dart';

class MockStudentFeedbackRepository implements StudentFeedbackRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  final List<FeedbackModel> _feedbackItems = [
    FeedbackModel(
      id: 'fb-1',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      rating: 5,
      comment: 'Excellent teaching methods and clear explanations.',
      createdAt: DateTime(2024, 3, 10),
      status: 'submitted',
    ),
    FeedbackModel(
      id: 'fb-2',
      subjectId: 'physics',
      subjectName: 'Physics',
      rating: 4,
      comment: 'Great lab sessions, but the lectures could be more interactive.',
      createdAt: DateTime(2024, 3, 15),
      status: 'submitted',
    ),
    FeedbackModel(
      id: 'fb-3',
      subjectId: 'literature',
      subjectName: 'Literature',
      rating: 3,
      comment: 'The reading list is too long for the given timeframe.',
      createdAt: DateTime(2024, 3, 20),
      status: 'reviewed',
    ),
    FeedbackModel(
      id: 'fb-4',
      subjectId: 'history',
      subjectName: 'History',
      rating: 5,
      createdAt: DateTime(2024, 3, 25),
      status: 'submitted',
    ),
  ];

  int _nextId = 5;

  @override
  Future<List<FeedbackModel>> fetchFeedbackHistory() async {
    await Future<void>.delayed(_latency);
    return List<FeedbackModel>.from(_feedbackItems);
  }

  @override
  Future<FeedbackModel> submitFeedback({
    required String subjectId,
    required String subjectName,
    required int rating,
    String? comment,
  }) async {
    await Future<void>.delayed(_latency);
    final feedback = FeedbackModel(
      id: 'fb-${_nextId++}',
      subjectId: subjectId,
      subjectName: subjectName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      status: 'submitted',
    );
    _feedbackItems.add(feedback);
    return feedback;
  }
}
