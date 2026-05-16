import 'package:equatable/equatable.dart';
import '../models/assignment_model.dart';

enum AssignmentsStatus { initial, loading, loaded, error }

class AssignmentsState extends Equatable {
  final AssignmentsStatus status;
  final List<AssignmentModel> assignments;
  final AssignmentStatus? activeFilter;
  final bool isSubmitting;
  final String? errorMessage;

  const AssignmentsState({
    this.status = AssignmentsStatus.initial,
    this.assignments = const [],
    this.activeFilter,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Returns only the assignments matching [activeFilter], or all if null.
  List<AssignmentModel> get filtered {
    final filter = activeFilter;
    if (filter == null) return assignments;
    return assignments.where((a) => a.status == filter).toList();
  }

  AssignmentsState copyWith({
    AssignmentsStatus? status,
    List<AssignmentModel>? assignments,
    AssignmentStatus? activeFilter,
    bool clearFilter = false,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AssignmentsState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        assignments,
        activeFilter,
        isSubmitting,
        errorMessage,
      ];
}
