import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/student_analytics_repository.dart';
import 'attendance_insights_state.dart';

class AttendanceInsightsCubit extends Cubit<AttendanceInsightsState> {
  final StudentAnalyticsRepository _repository;

  AttendanceInsightsCubit(this._repository)
    : super(const AttendanceInsightsState());

  Future<void> loadInsights() async {
    emit(state.copyWith(status: AttendanceInsightsStatus.loading));
    try {
      final insight = await _repository.fetchAttendanceInsight();
      emit(
        state.copyWith(
          status: AttendanceInsightsStatus.loaded,
          insight: insight,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AttendanceInsightsStatus.error,
          errorMessage: 'Unable to load attendance insights.',
        ),
      );
    }
  }
}
