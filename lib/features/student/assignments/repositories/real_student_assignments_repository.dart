import '../models/assignment_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import 'student_assignments_repository.dart';

/// Production-only assignments repository.
///
/// No mock fallback. Failed API calls propagate as exceptions so the UI can
/// display an accurate error state — silent local mutations are gone.
class RealStudentAssignmentsRepository implements StudentAssignmentsRepository {
  final ApiClient _api;

  static const Duration _ttl = Duration(seconds: 30);

  static List<AssignmentModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AssignmentModel>>? _inFlight;

  RealStudentAssignmentsRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<List<AssignmentModel>> fetchAssignments() async {
    if (_isCacheValid()) return _cache!;

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      return data;
    } finally {
      _inFlight = null;
    }
  }

  @override
  Future<List<AssignmentModel>> refresh() async {
    _bustCache();
    return fetchAssignments();
  }

  @override
  Future<AssignmentModel> fetchAssignmentById(String id) async {
    final raw = await _api.get(ApiConstants.assignmentById(id));
    final remote = _mapRemote(raw);
    _upsertCache(remote);
    return remote;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  @override
  Future<void> submitAssignment(String id, String content) async {
    await submitAssignmentWithFile(id, content);
  }

  @override
  Future<void> submitAssignmentWithFile(
    String id,
    String content, {
    String? filePath,
  }) async {
    final trimmed = content.trim();

    // Build request payload. Use multipart if a file is attached.
    if (filePath != null && filePath.isNotEmpty) {
      await _api.uploadFile(
        ApiConstants.assignmentSubmission(id),
        filePath,
        fieldName: 'attachment',
        additionalData: {'content': trimmed},
      );
    } else {
      await _api.post(
        ApiConstants.assignmentSubmission(id),
        data: {'content': trimmed},
      );
    }

    // Optimistically refresh the cache so the UI reflects the submission.
    _bustCache();
    await fetchAssignments();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  bool _isCacheValid() {
    if (_cache == null || _fetchedAt == null) return false;
    return DateTime.now().difference(_fetchedAt!) < _ttl;
  }

  void _bustCache() {
    _cache = null;
    _fetchedAt = null;
  }

  Future<List<AssignmentModel>> _fetchFresh() async {
    // Throws on failure — no silent fallback.
    final rows = await _api.getList(ApiConstants.assignmentsMe);
    return rows.whereType<Map<String, dynamic>>().map(_mapRemote).toList();
  }

  void _upsertCache(AssignmentModel item) {
    final current = List<AssignmentModel>.from(_cache ?? const []);
    final index = current.indexWhere((a) => a.id == item.id);
    if (index == -1) {
      current.add(item);
    } else {
      current[index] = item;
    }
    _cache = current;
  }

  AssignmentModel _mapRemote(Map<String, dynamic> raw) {
    final dueDate =
        DateTime.tryParse((raw['dueDate'] ?? '').toString()) ?? DateTime.now();
    final score = _asNullableDouble(raw['score']);
    final maxScore = _asNullableDouble(raw['maxScore']);
    final submittedAt = DateTime.tryParse(
      (raw['submittedAt'] ?? '').toString(),
    );

    return AssignmentModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Assignment').toString(),
      subject: (raw['subject'] ?? 'General').toString(),
      description: (raw['description'] ?? '').toString(),
      dueDate: dueDate,
      status: _parseStatus(
        (raw['status'] ?? '').toString(),
        dueDate: dueDate,
      ),
      score: score,
      maxScore: maxScore,
      feedback: raw['feedback']?.toString(),
      submittedAt: submittedAt,
      submittedContent: raw['submittedContent']?.toString(),
    );
  }

  AssignmentStatus _parseStatus(String raw, {required DateTime dueDate}) {
    switch (raw.toLowerCase()) {
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'graded':
        return AssignmentStatus.graded;
      case 'overdue':
        return AssignmentStatus.overdue;
      case 'pending':
        return AssignmentStatus.pending;
      default:
        return dueDate.isBefore(DateTime.now())
            ? AssignmentStatus.overdue
            : AssignmentStatus.pending;
    }
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
