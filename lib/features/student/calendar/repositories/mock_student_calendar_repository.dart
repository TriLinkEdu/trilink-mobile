import '../models/calendar_event_model.dart';
import 'student_calendar_repository.dart';

class MockStudentCalendarRepository implements StudentCalendarRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static List<CalendarEventModel> _buildEvents() {
    final now = DateTime.now();
    return [
      ..._eventsForMonth(now.year, now.month - 1, 'prev'),
      ..._eventsForMonth(now.year, now.month, 'cur'),
      ..._eventsForMonth(now.year, now.month + 1, 'next'),
    ];
  }

  static List<CalendarEventModel> _eventsForMonth(
    int year,
    int rawMonth,
    String prefix,
  ) {
    final dt = DateTime(year, rawMonth);
    final y = dt.year;
    final m = dt.month;

    return [
      CalendarEventModel(
        id: '${prefix}_ev1',
        title: 'Calculus Midterm',
        description:
            'Covers chapters 1-6: limits, derivatives, and basic integration.',
        startTime: DateTime(y, m, 5, 9, 0),
        endTime: DateTime(y, m, 5, 10, 30),
        type: 'exam',
        subjectId: 'mathematics',
        location: 'Hall A, Room 101',
      ),
      CalendarEventModel(
        id: '${prefix}_ev2',
        title: 'Physics Lab Session',
        description: 'Electromagnetic induction experiment.',
        startTime: DateTime(y, m, 8, 14, 0),
        endTime: DateTime(y, m, 8, 16, 0),
        type: 'class',
        subjectId: 'physics',
        location: 'Science Building, Lab 3',
      ),
      CalendarEventModel(
        id: '${prefix}_ev3',
        title: 'Literature Discussion',
        description:
            'Group discussion on Romantic poetry and its modern influence.',
        startTime: DateTime(y, m, 10, 11, 0),
        endTime: DateTime(y, m, 10, 12, 30),
        type: 'class',
        subjectId: 'literature',
        location: 'Humanities Wing, Room 204',
      ),
      CalendarEventModel(
        id: '${prefix}_ev4',
        title: 'Campus Career Fair',
        description:
            'Annual career fair with tech companies and research labs.',
        startTime: DateTime(y, m, 12, 10, 0),
        endTime: DateTime(y, m, 12, 16, 0),
        type: 'event',
        location: 'Student Union Building',
      ),
      CalendarEventModel(
        id: '${prefix}_ev5',
        title: 'Physics Quiz',
        description: 'Short quiz on Newton\'s laws and kinematics.',
        startTime: DateTime(y, m, 15, 9, 0),
        endTime: DateTime(y, m, 15, 9, 45),
        type: 'exam',
        subjectId: 'physics',
        location: 'Hall B, Room 203',
      ),
      CalendarEventModel(
        id: '${prefix}_ev6',
        title: 'Study Session: Linear Algebra',
        description:
            'Personal study block for eigenvalues and matrix decomposition.',
        startTime: DateTime(y, m, 17, 18, 0),
        endTime: DateTime(y, m, 17, 20, 0),
        type: 'personal',
      ),
      CalendarEventModel(
        id: '${prefix}_ev7',
        title: 'Math Lecture: Series & Sequences',
        description: 'Lecture on convergence tests and power series.',
        startTime: DateTime(y, m, 20, 10, 0),
        endTime: DateTime(y, m, 20, 11, 30),
        type: 'class',
        subjectId: 'mathematics',
        location: 'Hall A, Room 102',
      ),
      CalendarEventModel(
        id: '${prefix}_ev8',
        title: 'Literature Essay Deadline',
        description:
            'Final submission for the Romantic period comparative essay.',
        startTime: DateTime(y, m, 22, 23, 59),
        endTime: DateTime(y, m, 22, 23, 59),
        type: 'event',
        subjectId: 'literature',
      ),
      CalendarEventModel(
        id: '${prefix}_ev9',
        title: 'Gym & Workout',
        description: 'Weekly personal fitness session.',
        startTime: DateTime(y, m, 24, 17, 0),
        endTime: DateTime(y, m, 24, 18, 30),
        type: 'personal',
        location: 'Campus Gym',
      ),
      CalendarEventModel(
        id: '${prefix}_ev10',
        title: 'End-of-Month Review Meeting',
        description:
            'Academic advisor meeting to review monthly progress.',
        startTime: DateTime(y, m, 28, 14, 0),
        endTime: DateTime(y, m, 28, 15, 0),
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

  @override
  void clearCache() {}
}
