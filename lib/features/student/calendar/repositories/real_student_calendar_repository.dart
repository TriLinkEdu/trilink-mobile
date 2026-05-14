import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/calendar_event_model.dart';
import 'student_calendar_repository.dart';

class RealStudentCalendarRepository implements StudentCalendarRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static final Map<String, List<CalendarEventModel>> _cacheByKey = {};
  static final Map<String, DateTime> _fetchedAtByKey = {};
  static final Map<String, Future<List<CalendarEventModel>>> _inFlightByKey =
      {};
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentCalendarRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<CalendarEventModel>> fetchEvents({DateTime? month}) async {
    final target = month ?? DateTime.now();
    final userId = await _currentUserId();
    final cacheKey = _cacheKey(userId, target);
    _restoreCache(cacheKey);

    final cached = _cacheByKey[cacheKey];
    final fetchedAt = _fetchedAtByKey[cacheKey];
    if (cached != null && fetchedAt != null) {
      final age = DateTime.now().difference(fetchedAt);
      if (age < _ttl) return cached;
    }

    final inFlight = _inFlightByKey[cacheKey];
    if (inFlight != null) return inFlight;

    final from = DateTime(target.year, target.month, 1);
    final to = DateTime(target.year, target.month + 1, 0);

    final future = _api.getList(
      ApiConstants.calendarEvents,
      queryParameters: {'from': _dateOnly(from), 'to': _dateOnly(to)},
    ).then((rows) {
      final events = rows
          .whereType<Map<String, dynamic>>()
          .map(_mapEvent)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    });

    _inFlightByKey[cacheKey] = future;
    try {
      final events = await future;
      _cacheByKey[cacheKey] = events;
      _fetchedAtByKey[cacheKey] = DateTime.now();
      await _cacheService.write(
        cacheKey,
        events.map((item) => item.toJson()).toList(),
      );
      return events;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    } finally {
      _inFlightByKey.remove(cacheKey);
    }
  }

  @override
  Future<CalendarEventModel> fetchEventById(String id) async {
    final cached = _cachedEvent(id);
    if (cached != null) return cached;

    try {
      final raw = await _api.get('${ApiConstants.calendarEvents}/$id');
      final event = _mapEvent(raw);
      await _upsertEvent(await _currentUserId(), event);
      return event;
    } catch (_) {
      // Fallback for older backend deployments without /calendar-events/:id
      final now = DateTime.now();
      final rows = await _api.getList(
        ApiConstants.calendarEvents,
        queryParameters: {
          'from': _dateOnly(DateTime(now.year - 1, now.month, now.day)),
          'to': _dateOnly(DateTime(now.year + 1, now.month, now.day)),
        },
      );
      final events =
          rows.whereType<Map<String, dynamic>>().map(_mapEvent).toList();
      await _seedMonthCaches(await _currentUserId(), events);

      final match = events.where((e) => e.id == id);
      if (match.isNotEmpty) return match.first;
      throw StateError('Event not found');
    }
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

  CalendarEventModel? _cachedEvent(String id) {
    for (final list in _cacheByKey.values) {
      for (final event in list) {
        if (event.id == id) return event;
      }
    }
    return null;
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId, DateTime month) {
    final yyyy = month.year.toString();
    final mm = month.month.toString().padLeft(2, '0');
    if (userId.isEmpty) return 'student_calendar_$yyyy$mm';
    return 'student_calendar_${userId}_$yyyy$mm';
  }

  void _restoreCache(String cacheKey) {
    if (_cacheByKey.containsKey(cacheKey)) return;
    final entry = _cacheService.read(cacheKey);
    if (entry == null || entry.data is! List) return;
    _cacheByKey[cacheKey] = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(CalendarEventModel.fromJson)
        .toList();
    _fetchedAtByKey[cacheKey] = entry.savedAt;
  }

  Future<void> _upsertEvent(String userId, CalendarEventModel event) async {
    final key = _cacheKey(userId, event.startTime);
    final current = List<CalendarEventModel>.from(_cacheByKey[key] ?? const []);
    final index = current.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      current.add(event);
    } else {
      current[index] = event;
    }
    _cacheByKey[key] = current;
    _fetchedAtByKey[key] = DateTime.now();
    await _cacheService.write(
      key,
      current.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> _seedMonthCaches(
    String userId,
    List<CalendarEventModel> events,
  ) async {
    final grouped = <String, List<CalendarEventModel>>{};
    for (final event in events) {
      final key = _cacheKey(userId, event.startTime);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.startTime.compareTo(b.startTime));
      _cacheByKey[entry.key] = entry.value;
      _fetchedAtByKey[entry.key] = DateTime.now();
      await _cacheService.write(
        entry.key,
        entry.value.map((item) => item.toJson()).toList(),
      );
    }
  }
}
