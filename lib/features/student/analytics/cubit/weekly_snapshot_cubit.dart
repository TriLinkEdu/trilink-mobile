import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_analytics_repository.dart';
import 'weekly_snapshot_state.dart';

class WeeklySnapshotCubit extends Cubit<WeeklySnapshotState> {
  final StudentAnalyticsRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  WeeklySnapshotCubit(this._repository) : super(const WeeklySnapshotState());

  Future<void> loadIfNeeded() async {
    if (state.status == WeeklySnapshotStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadSnapshot();
  }

  Future<void> loadSnapshot() async {
    emit(state.copyWith(status: WeeklySnapshotStatus.loading));
    try {
      final snapshot = await _repository.fetchWeeklySnapshot();
      emit(
        state.copyWith(
          status: WeeklySnapshotStatus.loaded,
          snapshot: snapshot,
          errorMessage: null,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: WeeklySnapshotStatus.error,
          errorMessage: 'Unable to load weekly snapshot.',
        ),
      );
    }
  }
}
