import '../models/dashboard_data_model.dart';
import '../../shared/repositories/student_progress_repository.dart';
import 'student_dashboard_repository.dart';

class MockStudentDashboardRepository implements StudentDashboardRepository {
  static const Duration _latency = Duration(milliseconds: 350);
  final StudentProgressRepository _progressRepository;

  MockStudentDashboardRepository(this._progressRepository);

  @override
  Future<DashboardDataModel> fetchDashboardData() async {
    await Future<void>.delayed(_latency);
    final progress = await _progressRepository.fetchProgress();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);

    return DashboardDataModel(
      stats: DashboardStatsModel(
        streakDays: progress.currentStreak,
        totalXp: progress.totalXp,
        level: progress.level,
        levelTitle: progress.levelTitle,
        attendancePercent: 0.87,
      ),
      recentGradeHighlight: const DashboardRecentGradeHighlight(
        subjectName: 'Physics',
        scorePercent: 96,
      ),
      nextUp: NextUpItemModel(
        id: 'next-1',
        title: 'Physics Quiz',
        subtitle: 'Chapter 5: Mechanics',
        type: 'quiz',
        subjectId: 'physics',
        subjectName: 'Physics',
        dueAt: tomorrow,
        participantCount: 32,
      ),
      recentAnnouncements: [
        DashboardAnnouncementSnippet(
          id: 'ann-1',
          title: 'Mid-term Exam Schedule Released',
          authorName: 'Mr. Solomon',
          snippet:
              'The mid-term examination schedule for all Grade 11 students has been published. Please check the calendar for your subject-wise timetable.',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        DashboardAnnouncementSnippet(
          id: 'ann-2',
          title: 'Science Fair Registration Open',
          authorName: 'Ms. Tigist',
          snippet:
              'Registration for the annual science fair is now open. Teams of 2-4 students can sign up through the student portal by Friday.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  @override
  DashboardDataModel? getCached() => null;

  @override
  void clearCache() {}
}
