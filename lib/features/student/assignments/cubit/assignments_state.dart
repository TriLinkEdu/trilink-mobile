import 'package:equatable/equatable.dart';
import '../models/assignment_model.dart';

enum AssignmentsStatus { initial, loading, loaded, error }

class AssignmentsState extends Equatable {
  final AssignmentsStatus status;
  final List<AssignmentModel> assignments;
  final String? errorMessage;

  const AssignmentsState({
    this.status = AssignmentsStatus.initial,
    this.assignments = const [],
    this.errorMessage,
  });

  AssignmentsState copyWith({
    AssignmentsStatus? status,
    List<AssignmentModel>? assignments,
    String? errorMessage,
  }) {
    return AssignmentsState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, assignments, errorMessage];
}
