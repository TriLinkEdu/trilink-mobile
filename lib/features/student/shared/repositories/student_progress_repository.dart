import '../models/student_progress_model.dart';

abstract class StudentProgressRepository {
  Future<StudentProgressModel> fetchProgress();
}
