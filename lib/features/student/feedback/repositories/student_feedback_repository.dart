import '../models/feedback_model.dart';

abstract class StudentFeedbackRepository {
  Future<List<FeedbackModel>> fetchFeedbackHistory();
  Future<FeedbackModel> submitFeedback({
    required String subjectId,
    required String subjectName,
    required int rating,
    String? comment,
  });
}
