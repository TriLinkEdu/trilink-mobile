import '../models/sync_status_model.dart';
import 'student_sync_repository.dart';

class MockStudentSyncRepository implements StudentSyncRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  List<SyncItemModel> _items = [
    SyncItemModel(
      id: 'sync-grades',
      category: 'Grades',
      description: 'Student grade records',
      status: SyncItemStatus.synced,
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      pendingCount: 0,
    ),
    SyncItemModel(
      id: 'sync-attendance',
      category: 'Attendance',
      description: 'Daily attendance logs',
      status: SyncItemStatus.pending,
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 3)),
      pendingCount: 2,
    ),
    SyncItemModel(
      id: 'sync-assignments',
      category: 'Assignments',
      description: 'Assignment submissions and grades',
      status: SyncItemStatus.synced,
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      pendingCount: 0,
    ),
    SyncItemModel(
      id: 'sync-chat',
      category: 'Chat',
      description: 'Chat messages and conversations',
      status: SyncItemStatus.error,
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 6)),
      pendingCount: 5,
    ),
    SyncItemModel(
      id: 'sync-calendar',
      category: 'Calendar',
      description: 'Calendar events and reminders',
      status: SyncItemStatus.pending,
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 1)),
      pendingCount: 1,
    ),
  ];

  @override
  Future<List<SyncItemModel>> fetchSyncStatus() async {
    await Future<void>.delayed(_latency);
    return List<SyncItemModel>.from(_items);
  }

  @override
  Future<List<SyncItemModel>> triggerSync() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    _items = _items
        .map((item) => item.copyWith(
              status: SyncItemStatus.synced,
              lastSyncedAt: now,
              pendingCount: 0,
            ))
        .toList();
    return List<SyncItemModel>.from(_items);
  }
}
