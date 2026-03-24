import '../models/calendar_event_model.dart';
import 'student_calendar_repository.dart';

class MockStudentCalendarRepository implements StudentCalendarRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static List<CalendarEventModel> _buildEvents() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    return [
      CalendarEventModel(
        id: 'ev1',
        title: 'Calculus Midterm',
        description: 'Covers chapters 1-6: limits, derivatives, and basic integration.',
        startTime: DateTime(year, month, 5, 9, 0),
        endTime: DateTime(year, month, 5, 10, 30),
        type: 'exam',
        subjectId: 'mathematics',
        location: 'Hall A, Room 101',
      ),
      CalendarEventModel(
        id: 'ev2',
        title: 'Physics Lab Session',
        description: 'Electromagnetic induction experiment.',
        startTime: DateTime(year, month, 8, 14, 0),
        endTime: DateTime(year, month, 8, 16, 0),
        type: 'class',
        subjectId: 'physics',
        location: 'Science Building, Lab 3',
      ),
      CalendarEventModel(
        id: 'ev3',
        title: 'Literature Discussion',
        description: 'Group discussion on Romantic poetry and its modern influence.',
        startTime: DateTime(year, month, 10, 11, 0),
        endTime: DateTime(year, month, 10, 12, 30),
        type: 'class',
        subjectId: 'literature',
        location: 'Humanities Wing, Room 204',
      ),
      CalendarEventModel(
        id: 'ev4',
        title: 'Campus Career Fair',
        description: 'Annual career fair with tech companies and research labs.',
        startTime: DateTime(year, month, 12, 10, 0),
        endTime: DateTime(year, month, 12, 16, 0),
        type: 'event',
        location: 'Student Union Building',
      ),
      CalendarEventModel(
        id: 'ev5',
        title: 'Physics Quiz',
        description: 'Short quiz on Newton\'s laws and kinematics.',
        startTime: DateTime(year, month, 15, 9, 0),
        endTime: DateTime(year, month, 15, 9, 45),
        type: 'exam',
        subjectId: 'physics',
        location: 'Hall B, Room 203',
      ),
      CalendarEventModel(
        id: 'ev6',
        title: 'Study Session: Linear Algebra',
        description: 'Personal study block for eigenvalues and matrix decomposition.',
        startTime: DateTime(year, month, 17, 18, 0),
        endTime: DateTime(year, month, 17, 20, 0),
        type: 'personal',
      ),
      CalendarEventModel(
        id: 'ev7',
        title: 'Math Lecture: Series & Sequences',
        description: 'Lecture on convergence tests and power series.',
        startTime: DateTime(year, month, 20, 10, 0),
        endTime: DateTime(year, month, 20, 11, 30),
        type: 'class',
        subjectId: 'mathematics',
        location: 'Hall A, Room 102',
      ),
      CalendarEventModel(
        id: 'ev8',
        title: 'Literature Essay Deadline',
        description: 'Final submission for the Romantic period comparative essay.',
        startTime: DateTime(year, month, 22, 23, 59),
        endTime: DateTime(year, month, 22, 23, 59),
        type: 'event',
        subjectId: 'literature',
      ),
      CalendarEventModel(
        id: 'ev9',
        title: 'Gym & Workout',
        description: 'Weekly personal fitness session.',
        startTime: DateTime(year, month, 24, 17, 0),
        endTime: DateTime(year, month, 24, 18, 30),
        type: 'personal',
        location: 'Campus Gym',
      ),
      CalendarEventModel(
        id: 'ev10',
        title: 'End-of-Month Review Meeting',
        description: 'Academic advisor meeting to review monthly progress.',
        startTime: DateTime(year, month, 28, 14, 0),
        endTime: DateTime(year, month, 28, 15, 0),
        type: 'event',
        location: 'Administration Building, Office 12',
      ),
    ];
  }

  @override
  Future<List<CalendarEventModel>> fetchEvents({DateTime? month}) async {
    await Future<void>.delayed(_latency);
    final events = _buildEvents();
    if (month == null) return events;
    return events
        .where(
          (e) =>
              e.startTime.year == month.year &&
              e.startTime.month == month.month,
        )
        .toList();
  }

  @override
  Future<CalendarEventModel> fetchEventById(String id) async {
    await Future<void>.delayed(_latency);
    return _buildEvents().firstWhere((e) => e.id == id);
  }
}
