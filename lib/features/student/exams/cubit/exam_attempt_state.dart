import 'package:equatable/equatable.dart';
import '../models/exam_model.dart';

enum ExamAttemptStatus { initial, loading, loaded, error }

enum ExamSubmissionStatus { idle, submitting, success, error }

class ExamAttemptState extends Equatable {
  final ExamAttemptStatus status;
  final ExamModel? exam;
  final String? errorMessage;
  final String? attemptId;
  final ExamSubmissionStatus submissionStatus;
  final String? submissionErrorMessage;

  const ExamAttemptState({
    this.status = ExamAttemptStatus.initial,
    this.exam,
    this.errorMessage,
    this.attemptId,
    this.submissionStatus = ExamSubmissionStatus.idle,
    this.submissionErrorMessage,
  });

  ExamAttemptState copyWith({
    ExamAttemptStatus? status,
    ExamModel? exam,
    String? errorMessage,
    String? attemptId,
    ExamSubmissionStatus? submissionStatus,
    String? submissionErrorMessage,
  }) {
    return ExamAttemptState(
      status: status ?? this.status,
      exam: exam ?? this.exam,
      errorMessage: errorMessage,
      attemptId: attemptId ?? this.attemptId,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionErrorMessage: submissionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exam,
    errorMessage,
    attemptId,
    submissionStatus,
    submissionErrorMessage,
  ];
}
