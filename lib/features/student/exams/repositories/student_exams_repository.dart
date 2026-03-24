import '../models/exam_model.dart';

abstract class StudentExamsRepository {
  Future<List<ExamModel>> fetchAvailableExams();
  Future<ExamModel> fetchExamQuestions(String examId);
  Future<ExamResultModel> submitExam(String examId, Map<String, int> answers);
}
