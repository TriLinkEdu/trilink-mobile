import 'package:equatable/equatable.dart';
import '../models/assignment_model.dart';

enum AssignmentDetailStatus { initial, loading, loaded, error }

class AssignmentDetailState extends Equatable {
  final AssignmentDetailStatus status;
  final AssignmentModel? assignment;
  final String? errorMessage;

  const AssignmentDetailState({
    this.status = AssignmentDetailStatus.initial,
    this.assignment,
    this.errorMessage,
  });

  AssignmentDetailState copyWith({
    AssignmentDetailStatus? status,
    AssignmentModel? assignment,
    String? errorMessage,
  }) {
    return AssignmentDetailState(
      status: status ?? this.status,
      assignment: assignment ?? this.assignment,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, assignment, errorMessage];
}
