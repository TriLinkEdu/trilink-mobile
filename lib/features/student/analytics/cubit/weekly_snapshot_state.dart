import 'package:equatable/equatable.dart';

import '../models/student_growth_models.dart';

enum WeeklySnapshotStatus { initial, loading, loaded, error }

class WeeklySnapshotState extends Equatable {
  final WeeklySnapshotStatus status;
  final StudentWeeklySnapshot? snapshot;
  final String? errorMessage;

  const WeeklySnapshotState({
    this.status = WeeklySnapshotStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  WeeklySnapshotState copyWith({
    WeeklySnapshotStatus? status,
    StudentWeeklySnapshot? snapshot,
    String? errorMessage,
  }) {
    return WeeklySnapshotState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}
