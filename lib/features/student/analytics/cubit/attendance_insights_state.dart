import 'package:equatable/equatable.dart';

import '../models/student_growth_models.dart';

enum AttendanceInsightsStatus { initial, loading, loaded, error }

class AttendanceInsightsState extends Equatable {
  final AttendanceInsightsStatus status;
  final StudentAttendanceInsight? insight;
  final String? errorMessage;

  const AttendanceInsightsState({
    this.status = AttendanceInsightsStatus.initial,
    this.insight,
    this.errorMessage,
  });

  AttendanceInsightsState copyWith({
    AttendanceInsightsStatus? status,
    StudentAttendanceInsight? insight,
    String? errorMessage,
  }) {
    return AttendanceInsightsState(
      status: status ?? this.status,
      insight: insight ?? this.insight,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, insight, errorMessage];
}
