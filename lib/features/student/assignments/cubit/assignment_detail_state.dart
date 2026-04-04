import 'package:equatable/equatable.dart';
import '../models/assignment_model.dart';

enum AssignmentDetailStatus { initial, loading, loaded, error }

class AssignmentDetailState extends Equatable {
  final AssignmentDetailStatus status;
  final AssignmentModel? assignment;
  final String? errorMessage;
  final bool isSubmitting;
  final String? submitError;

  const AssignmentDetailState({
    this.status = AssignmentDetailStatus.initial,
    this.assignment,
    this.errorMessage,
    this.isSubmitting = false,
    this.submitError,
  });

  AssignmentDetailState copyWith({
    AssignmentDetailStatus? status,
    AssignmentModel? assignment,
    String? errorMessage,
    bool? isSubmitting,
    String? submitError,
  }) {
    return AssignmentDetailState(
      status: status ?? this.status,
      assignment: assignment ?? this.assignment,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }

  @override
  List<Object?> get props =>
      [status, assignment, errorMessage, isSubmitting, submitError];
}
