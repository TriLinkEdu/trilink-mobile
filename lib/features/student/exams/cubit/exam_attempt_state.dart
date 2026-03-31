import 'package:equatable/equatable.dart';
import '../models/exam_model.dart';

enum ExamAttemptStatus { initial, loading, loaded, error }

class ExamAttemptState extends Equatable {
  final ExamAttemptStatus status;
  final ExamModel? exam;
  final String? errorMessage;

  const ExamAttemptState({
    this.status = ExamAttemptStatus.initial,
    this.exam,
    this.errorMessage,
  });

  ExamAttemptState copyWith({
    ExamAttemptStatus? status,
    ExamModel? exam,
    String? errorMessage,
  }) {
    return ExamAttemptState(
      status: status ?? this.status,
      exam: exam ?? this.exam,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, exam, errorMessage];
}
