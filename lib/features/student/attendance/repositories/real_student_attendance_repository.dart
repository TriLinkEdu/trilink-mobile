import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/attendance_model.dart';
import 'student_attendance_repository.dart';

class RealStudentAttendanceRepository implements StudentAttendanceRepository {
  final ApiClient _api;
  final StorageService _storage;

  static List<AttendanceModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AttendanceModel>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentAttendanceRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<List<AttendanceModel>> fetchAttendanceRecords() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return data;
  }

  Future<List<AttendanceModel>> _fetchFresh() async {
    final studentId = await _resolveStudentId();
    final data = await _api.get(
      ApiConstants.attendanceStudentReport(studentId),
    );
    final records = data['records'];
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
    final subjectName = subject is Map<String, dynamic> 
        ? (subject['name'] ?? 'Unknown Subject').toString()
        : 'Unknown Subject';
    
    // Parse session date from the session object or fall back to top-level date
    final sessionDate = (raw['sessionDate'] ?? raw['date'] ?? '').toString();

    return AttendanceModel(
      id: markId.isNotEmpty ? markId : sessionId,
      subjectId: classOfferingId,
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
    final id = (user?['id'] ?? '').toString();
    if (id.isEmpty) {
      throw StateError('Student session not found. Please login again.');
    }
    return id;
  }
}
