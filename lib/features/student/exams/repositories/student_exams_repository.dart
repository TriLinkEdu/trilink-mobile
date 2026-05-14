import '../models/exam_model.dart';

abstract class StudentExamsRepository {
  Future<List<ExamModel>> fetchAvailableExams();
  Future<ExamModel> fetchExamQuestions(String examId);
  Future<ExamResultModel> submitExam(String examId, Map<String, int> answers);
  Future<ExamAttemptModel> startAttempt(String examId, String studentId);
  Future<ExamAttemptModel> submitAttempt(String attemptId, Map<String, int> answers);

  List<ExamModel>? getCached() => null;
  void clearCache() {}
}
