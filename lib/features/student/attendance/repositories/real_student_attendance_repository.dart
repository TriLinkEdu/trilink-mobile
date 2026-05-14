import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/attendance_model.dart';
import 'student_attendance_repository.dart';

class RealStudentAttendanceRepository implements StudentAttendanceRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static List<AttendanceModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AttendanceModel>>? _inFlight;
  static String? _cacheStudentId;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentAttendanceRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<AttendanceModel>> fetchAttendanceRecords() async {
    final studentId = await _resolveStudentId();
    _restoreCache(studentId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh(studentId);
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _cacheStudentId = studentId;
      _fetchedAt = DateTime.now();
      if (studentId.isNotEmpty) {
        await _cacheService.write(
          _cacheKey(studentId),
          data.map((item) => item.toJson()).toList(),
        );
      }
      return data;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<AttendanceModel>> _fetchFresh(String studentId) async {
    if (studentId.isEmpty) return const [];
    final data = await _api.get(
      ApiConstants.attendanceStudentReport(studentId),
    );
    final records = data['marks'];
    if (records is! List) return const [];

    return records.whereType<Map<String, dynamic>>().map(_mapRecord).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  AttendanceModel _mapRecord(Map<String, dynamic> raw) {
    final status = _parseStatus((raw['status'] ?? '').toString());
    final markId = (raw['markId'] ?? '').toString();
    final sessionId = (raw['sessionId'] ?? '').toString();
    final classOfferingId = (raw['classOfferingId'] ?? '').toString();
    
    // Extract subject info from nested object
    final subject = raw['subject'];
    final subjectId = subject is Map<String, dynamic>
        ? (subject['id'] ?? classOfferingId).toString()
        : classOfferingId;
    final subjectName = subject is Map<String, dynamic> 
        ? (subject['name'] ?? 'Unknown Subject').toString()
        : 'Unknown Subject';
    
    // Parse session date from the session object or fall back to top-level date
    final sessionDate = (raw['sessionDate'] ?? raw['date'] ?? '').toString();

    return AttendanceModel(
      id: markId.isNotEmpty ? markId : sessionId,
      subjectId: subjectId,
      subjectName: subjectName,
      date: DateTime.tryParse(sessionDate) ?? DateTime.now(),
      status: status,
    );
  }

  AttendanceStatus _parseStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  Future<String> _resolveStudentId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  void _restoreCache(String studentId) {
    if (_cache != null && _cacheStudentId == studentId) return;
    if (studentId.isEmpty) return;
    final entry = _cacheService.read(_cacheKey(studentId));
    if (entry == null || entry.data is! List) return;
    final records = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(AttendanceModel.fromJson)
        .toList();
    _cache = records;
    _cacheStudentId = studentId;
    _fetchedAt = entry.savedAt;
  }

  static String _cacheKey(String studentId) =>
      'student_attendance_records_v1_$studentId';
}
