import '../models/calendar_event_model.dart';

abstract class StudentCalendarRepository {
  Future<List<CalendarEventModel>> fetchEvents({DateTime? month});
  Future<CalendarEventModel> fetchEventById(String id);
  void clearCache() {}
}
