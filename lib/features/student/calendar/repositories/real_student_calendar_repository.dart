import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/calendar_event_model.dart';
import 'student_calendar_repository.dart';

class RealStudentCalendarRepository implements StudentCalendarRepository {
  final ApiClient _api;
  List<CalendarEventModel> _cache = const [];

  RealStudentCalendarRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<CalendarEventModel>> fetchEvents({DateTime? month}) async {
    final target = month ?? DateTime.now();
    final from = DateTime(target.year, target.month, 1);
    final to = DateTime(target.year, target.month + 1, 0);

    final rows = await _api.getList(
      ApiConstants.calendarEvents,
      queryParameters: {'from': _dateOnly(from), 'to': _dateOnly(to)},
    );

    final events =
        rows.whereType<Map<String, dynamic>>().map(_mapEvent).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _cache = events;
    return events;
  }

  @override
  Future<CalendarEventModel> fetchEventById(String id) async {
    final cached = _cache.where((e) => e.id == id);
    if (cached.isNotEmpty) return cached.first;

    final now = DateTime.now();
    final rows = await _api.getList(
      ApiConstants.calendarEvents,
      queryParameters: {
        'from': _dateOnly(DateTime(now.year - 1, now.month, now.day)),
        'to': _dateOnly(DateTime(now.year + 1, now.month, now.day)),
      },
    );
    final events = rows
        .whereType<Map<String, dynamic>>()
        .map(_mapEvent)
        .toList();
    _cache = events;

    final match = events.where((e) => e.id == id);
    if (match.isNotEmpty) return match.first;
    throw StateError('Event not found');
  }

  CalendarEventModel _mapEvent(Map<String, dynamic> raw) {
    final date = (raw['date'] ?? '').toString();
    final time = (raw['time'] ?? '').toString();
    final start = _parseStart(date, time);

    return CalendarEventModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Event').toString(),
      description: (raw['description'] ?? '').toString().isEmpty
          ? null
          : (raw['description'] as String),
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      type: (raw['type'] ?? 'event').toString(),
      subjectId: (raw['classOfferingId'] ?? '').toString().isEmpty
          ? null
          : (raw['classOfferingId'] as String),
      location: null,
    );
  }

  DateTime _parseStart(String date, String time) {
    final safeDate = DateTime.tryParse(date);
    if (safeDate == null) return DateTime.now();

    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(safeDate.year, safeDate.month, safeDate.day, hour, minute);
  }

  String _dateOnly(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }
}
