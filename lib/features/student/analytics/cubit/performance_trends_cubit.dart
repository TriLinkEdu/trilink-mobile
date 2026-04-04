import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_analytics_repository.dart';
import 'performance_trends_state.dart';

class PerformanceTrendsCubit extends Cubit<PerformanceTrendsState> {
  final StudentAnalyticsRepository _repository;

  PerformanceTrendsCubit(this._repository)
    : super(const PerformanceTrendsState());

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
