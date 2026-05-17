import '../models/announcement_model.dart';
import 'student_announcements_repository.dart';

class MockStudentAnnouncementsRepository
    implements StudentAnnouncementsRepository {
  static const Duration _latency = Duration(milliseconds: 300);

  static final List<AnnouncementModel> _announcements = [
    AnnouncementModel(
      id: 'a1',
      title: 'Campus Closure Alert',
      body:
          'Due to severe weather conditions expected this afternoon, all campus activities are suspended.',
      authorName: 'Administration',
      authorRole: 'Admin',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      category: 'calendar',
    ),
    AnnouncementModel(
      id: 'a2',
      title: 'Final Exam Schedule',
      body:
          'The schedule for the Spring 2024 final exams has been posted. Please review your timetable.',
      authorName: 'Registrar Office',
      authorRole: 'Admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      category: 'calendar',
    ),
    AnnouncementModel(
      id: 'a3',
      title: 'Biology 101 Class Update',
      body:
          'Due to an unforeseen emergency, today\'s lecture is cancelled. Materials are uploaded online.',
      authorName: 'Dr. Sarah Johnson',
      authorRole: 'Teacher',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      category: 'general',
    ),
    AnnouncementModel(
      id: 'a4',
      title: 'New Assignment Posted',
      body:
          'The project requirements for Intro to Algorithms have been uploaded to the portal.',
      authorName: 'Prof. Alan Turing',
      authorRole: 'Teacher',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      category: 'exam',
    ),
  ];

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    await Future<void>.delayed(_latency);
    return List<AnnouncementModel>.from(_announcements);
  }

  @override
  List<AnnouncementModel>? getCached() => null;

  @override
  void clearCache() {}
}
