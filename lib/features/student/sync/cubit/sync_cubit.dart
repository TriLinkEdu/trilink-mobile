import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_sync_repository.dart';
import 'sync_state.dart';

export 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final StudentSyncRepository _repository;

  SyncCubit(this._repository) : super(const SyncState());

  Future<void> loadSyncStatus() async {
    emit(state.copyWith(status: SyncStatus.loading));
    try {
      final items = await _repository.fetchSyncStatus();
      emit(SyncState(status: SyncStatus.loaded, items: items));
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
  }
}
