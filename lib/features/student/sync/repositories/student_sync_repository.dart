import '../models/sync_status_model.dart';

abstract class StudentSyncRepository {
  Future<List<SyncItemModel>> fetchSyncStatus();
  Future<List<SyncItemModel>> triggerSync();
}
