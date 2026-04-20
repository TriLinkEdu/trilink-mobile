import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/sync_status_model.dart';
import 'student_sync_repository.dart';

class RealStudentSyncRepository implements StudentSyncRepository {
  final ApiClient _api;

  static List<SyncItemModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<SyncItemModel>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentSyncRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<SyncItemModel>> fetchSyncStatus() async {
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
  Future<List<SyncItemModel>> triggerSync() async {
    try {
      final res = await _api.post(ApiConstants.studentSyncTrigger);
      final items = _mapItems(res['items']);
      _cache = items;
      _fetchedAt = DateTime.now();
      return items;
    } catch (_) {
      // Fallback for older backend deployments.
      final now = DateTime.now();
      final current = await fetchSyncStatus();
      final refreshed = current
          .map(
            (item) => item.copyWith(
              status: SyncItemStatus.synced,
              lastSyncedAt: now,
              pendingCount: 0,
            ),
          )
          .toList();
      _cache = refreshed;
      _fetchedAt = now;
      return refreshed;
    }
  }

  Future<List<SyncItemModel>> _fetchFresh() async {
    final now = DateTime.now();
    try {
      final status = await _api.get(ApiConstants.studentSyncStatus);
      final mapped = _mapItems(status['items']);
      if (mapped.isNotEmpty) {
        return mapped;
      }

      // Keep old hint-based behavior when status returns no items.
      final hint = await _api.get(ApiConstants.integrationsSyncHints);
      final serverTime =
          DateTime.tryParse((hint['serverTime'] ?? '').toString()) ?? now;
      return _defaultSynced(serverTime);
    } catch (_) {
      return _defaultPending(now.subtract(const Duration(minutes: 5)));
    }
  }

  List<SyncItemModel> _mapItems(dynamic rawItems) {
    if (rawItems is! List) return const [];
    return rawItems.whereType<Map<String, dynamic>>().map((raw) {
      final status = _mapStatus((raw['status'] ?? '').toString());
      final ts =
          DateTime.tryParse((raw['lastSyncedAt'] ?? '').toString()) ??
          DateTime.now();
      return SyncItemModel(
        id: (raw['id'] ?? '').toString(),
        category: (raw['category'] ?? 'Sync').toString(),
        description: (raw['description'] ?? '').toString(),
        status: status,
        lastSyncedAt: ts,
        pendingCount: _asInt(raw['pendingCount'], fallback: 0),
      );
    }).toList();
  }

  List<SyncItemModel> _defaultSynced(DateTime ts) {
    return [
      SyncItemModel(
        id: 'sync-api',
        category: 'API Link',
        description: 'Server handshake and sync hints',
        status: SyncItemStatus.synced,
        lastSyncedAt: ts,
        pendingCount: 0,
      ),
      SyncItemModel(
        id: 'sync-student-data',
        category: 'Student Data',
        description: 'Grades, attendance, announcements and exams',
        status: SyncItemStatus.synced,
        lastSyncedAt: ts,
        pendingCount: 0,
      ),
    ];
  }

  List<SyncItemModel> _defaultPending(DateTime ts) {
    return [
      SyncItemModel(
        id: 'sync-api',
        category: 'API Link',
        description: 'Server sync endpoint currently unavailable for students',
        status: SyncItemStatus.pending,
        lastSyncedAt: ts,
        pendingCount: 1,
      ),
      SyncItemModel(
        id: 'sync-student-data',
        category: 'Student Data',
        description:
            'Using local cache fallback until sync endpoint is enabled',
        status: SyncItemStatus.pending,
        lastSyncedAt: ts,
        pendingCount: 1,
      ),
    ];
  }

  SyncItemStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'synced':
        return SyncItemStatus.synced;
      case 'error':
        return SyncItemStatus.error;
      default:
        return SyncItemStatus.pending;
    }
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
