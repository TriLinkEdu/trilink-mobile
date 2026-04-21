import '../models/assignment_model.dart';
import 'student_assignments_repository.dart';

class RealStudentAssignmentsRepository implements StudentAssignmentsRepository {
  final StudentAssignmentsRepository _fallback;

  static const Duration _ttl = Duration(seconds: 30);

  static List<AssignmentModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AssignmentModel>>? _inFlight;

  RealStudentAssignmentsRepository({
    required StudentAssignmentsRepository fallback,
  }) : _fallback = fallback;

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
    final all = await fetchAssignments();
    for (final item in all) {
      if (item.id == id) return item;
    }
    throw StateError('Assignment not found');
  }

  @override
  Future<void> submitAssignment(String id, String content) async {
    final all = await fetchAssignments();
    final index = all.indexWhere((a) => a.id == id);
    if (index == -1) throw StateError('Assignment not found');

    final updated = List<AssignmentModel>.from(all);
    updated[index] = updated[index].copyWith(
      status: AssignmentStatus.submitted,
      submittedAt: DateTime.now(),
      submittedContent: content,
    );

    _cache = updated;
    _fetchedAt = DateTime.now();
  }

  Future<List<AssignmentModel>> _fetchFresh() async {
    try {
      return await _fallback.fetchAssignments();
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    }
  }
}
