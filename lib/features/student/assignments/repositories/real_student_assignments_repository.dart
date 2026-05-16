import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import 'student_assignments_repository.dart';

/// Production-only assignments repository.
///
/// No mock fallback. Failed API calls propagate as exceptions so the UI can
/// display an accurate error state — silent local mutations are gone.
class RealStudentAssignmentsRepository implements StudentAssignmentsRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static const Duration _ttl = Duration(minutes: 10);

  List<AssignmentModel>? _cache;
  DateTime? _fetchedAt;
  Future<List<AssignmentModel>>? _inFlight;

  RealStudentAssignmentsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<List<AssignmentModel>> fetchAssignments() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_isCacheValid()) return _cache!;

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      await _persistCache(userId);
      return data;
    } catch (e) {
      debugPrint('[AssignmentsRepo] fetchAssignments error: $e');
      if (_cache != null) return _cache!;
      rethrow;
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
    await _persistCache(await _currentUserId());
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
    debugPrint('[AssignmentsRepo] fetching ${ApiConstants.assignmentsMe}');
    final rows = await _api.getList(ApiConstants.assignmentsMe);
    debugPrint('[AssignmentsRepo] received ${rows.length} items');
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

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_assignments_v1'
      : 'student_assignments_v1_$userId';

  @override
  List<AssignmentModel>? getCached() => _cache;

  @override
  void clearCache() {
    _cache = null;
    _fetchedAt = null;
    _inFlight = null;
  }

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! List) return;
    _cache = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(AssignmentModel.fromJson)
        .toList();
    _fetchedAt = entry.savedAt;
  }

  Future<void> _persistCache(String userId) async {
    if (_cache == null) return;
    await _cacheService.write(
      _cacheKey(userId),
      _cache!.map((item) => item.toJson()).toList(),
    );
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
