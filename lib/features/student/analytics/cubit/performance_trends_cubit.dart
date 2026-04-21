import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_analytics_repository.dart';
import 'performance_trends_state.dart';

class PerformanceTrendsCubit extends Cubit<PerformanceTrendsState> {
  final StudentAnalyticsRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  PerformanceTrendsCubit(this._repository)
    : super(const PerformanceTrendsState());

  Future<void> loadIfNeeded() async {
    if (state.status == PerformanceTrendsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadTrends();
  }

  Future<void> loadTrends() async {
    emit(state.copyWith(status: PerformanceTrendsStatus.loading));
    try {
      final trends = await _repository.fetchPerformanceTrends();
      emit(
        state.copyWith(
          status: PerformanceTrendsStatus.loaded,
          trends: trends,
          errorMessage: null,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (_) {
      emit(
        state.copyWith(
          status: PerformanceTrendsStatus.error,
          errorMessage: 'Unable to load performance trends.',
        ),
      );
    }
  }
}
