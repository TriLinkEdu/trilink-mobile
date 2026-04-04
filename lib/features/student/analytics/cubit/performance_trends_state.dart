import 'package:equatable/equatable.dart';

import '../models/student_growth_models.dart';

enum PerformanceTrendsStatus { initial, loading, loaded, error }

class PerformanceTrendsState extends Equatable {
  final PerformanceTrendsStatus status;
  final StudentPerformanceTrends? trends;
  final String? errorMessage;

  const PerformanceTrendsState({
    this.status = PerformanceTrendsStatus.initial,
    this.trends,
    this.errorMessage,
  });

  PerformanceTrendsState copyWith({
    PerformanceTrendsStatus? status,
    StudentPerformanceTrends? trends,
    String? errorMessage,
  }) {
    return PerformanceTrendsState(
      status: status ?? this.status,
      trends: trends ?? this.trends,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, trends, errorMessage];
}
