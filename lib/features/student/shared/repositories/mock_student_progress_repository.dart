import '../models/student_progress_model.dart';
import 'student_progress_repository.dart';

class MockStudentProgressRepository implements StudentProgressRepository {
  static const Duration _latency = Duration(milliseconds: 220);

  static const StudentProgressModel _progress = StudentProgressModel(
    currentStreak: 12,
    longestStreak: 25,
    totalXp: 850,
    level: 12,
    levelTitle: 'Scholar',
  );

  @override
  Future<StudentProgressModel> fetchProgress() async {
    await Future<void>.delayed(_latency);
    return _progress;
  }
}
