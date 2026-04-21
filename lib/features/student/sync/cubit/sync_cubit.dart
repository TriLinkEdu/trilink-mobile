import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_sync_repository.dart';
import 'sync_state.dart';

export 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final StudentSyncRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 20);

  SyncCubit(this._repository) : super(const SyncState());

  Future<void> loadIfNeeded() async {
    if (state.status == SyncStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadSyncStatus();
  }

  Future<void> loadSyncStatus() async {
    emit(state.copyWith(status: SyncStatus.loading));
    try {
      final items = await _repository.fetchSyncStatus();
      emit(SyncState(status: SyncStatus.loaded, items: items));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Unable to load sync status.',
        ),
      );
    }
  }

  Future<void> triggerSync() async {
    final items = await _repository.triggerSync();
    emit(SyncState(status: SyncStatus.loaded, items: items));
    _lastLoadedAt = DateTime.now();
  }
}
