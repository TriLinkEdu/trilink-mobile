import '../models/assignment_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import 'student_assignments_repository.dart';

class RealStudentAssignmentsRepository implements StudentAssignmentsRepository {
  final ApiClient _api;
  final StudentAssignmentsRepository _fallback;

  static const Duration _ttl = Duration(seconds: 30);

  static List<AssignmentModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AssignmentModel>>? _inFlight;

  RealStudentAssignmentsRepository({
    ApiClient? apiClient,
    required StudentAssignmentsRepository fallback,
  }) : _api = apiClient ?? ApiClient(),
       _fallback = fallback;

  @override
  Future<List<AssignmentModel>> fetchAssignments() async {
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

  @override
  Future<AssignmentModel> fetchAssignmentById(String id) async {
    try {
      final raw = await _api.get(ApiConstants.assignmentById(id));
      final remote = _mapRemote(raw);
      _upsertCache(remote);
      return remote;
    } catch (_) {
      final all = await fetchAssignments();
      for (final item in all) {
        if (item.id == id) return item;
      }
      throw StateError('Assignment not found');
    }
  }

  @override
  Future<void> submitAssignment(String id, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    try {
      final raw = await _api.post(
        ApiConstants.assignmentSubmission(id),
        data: {'content': trimmed},
      );
      final remote = _mapRemote(raw);
      _upsertCache(remote);
      _fetchedAt = DateTime.now();
      return;
    } catch (_) {
      final all = await fetchAssignments();
      final index = all.indexWhere((a) => a.id == id);
      if (index == -1) throw StateError('Assignment not found');

      final updated = List<AssignmentModel>.from(all);
      updated[index] = updated[index].copyWith(
        status: AssignmentStatus.submitted,
        submittedAt: DateTime.now(),
        submittedContent: trimmed,
      );

      _cache = updated;
      _fetchedAt = DateTime.now();
    }
  }

  Future<List<AssignmentModel>> _fetchFresh() async {
    try {
      final rows = await _api.getList(ApiConstants.assignmentsMe);
      return rows.whereType<Map<String, dynamic>>().map(_mapRemote).toList();
    } catch (_) {
      try {
        return await _fallback.fetchAssignments();
      } catch (_) {
        if (_cache != null) return _cache!;
        rethrow;
      }
    }
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

    final status = _parseStatus(
      (raw['status'] ?? '').toString(),
      dueDate: dueDate,
    );

    return AssignmentModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Assignment').toString(),
      subject: (raw['subject'] ?? 'General').toString(),
      description: (raw['description'] ?? '').toString(),
      dueDate: dueDate,
      status: status,
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
