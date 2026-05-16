import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_dashboard_repository.dart';
import 'dashboard_state.dart';

export 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final StudentDashboardRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(minutes: 10);

  DashboardCubit(this._repository) : super(const DashboardState());

  Future<void> loadIfNeeded() async {
    // Cubit still alive and data is fresh — skip entirely.
    if (state.status == DashboardStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) return;

    // SWR: show cached data immediately, then background-refresh.
    final cached = _repository.getCached();
    if (cached != null) {
      if (state.status != DashboardStatus.loaded) {
        emit(DashboardState(status: DashboardStatus.loaded, data: cached));
      }
      unawaited(_silentRefresh());
      return;
    }

    // Truly cold — show skeleton and wait.
    await loadDashboard();
  }

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.fetchDashboardData();
      emit(DashboardState(status: DashboardStatus.loaded, data: data));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await _repository.fetchDashboardData();
      if (!isClosed) {
        emit(DashboardState(status: DashboardStatus.loaded, data: data));
        _lastLoadedAt = DateTime.now();
      }
    } catch (_) {} // keep showing cached data on network failure
  }
}
