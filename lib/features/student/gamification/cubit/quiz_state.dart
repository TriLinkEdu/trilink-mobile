import 'package:equatable/equatable.dart';

import '../../exams/models/exam_model.dart';

enum QuizLoadStatus { initial, loading, loaded, error }

class QuizState extends Equatable {
  final QuizLoadStatus status;
  final ExamModel? quiz;
  final String? errorMessage;
  final bool submitting;
  final ExamResultModel? submitResult;

  const QuizState({
    this.status = QuizLoadStatus.initial,
    this.quiz,
    this.errorMessage,
    this.submitting = false,
    this.submitResult,
  });

  QuizState copyWith({
    QuizLoadStatus? status,
    ExamModel? quiz,
    String? errorMessage,
    bool? submitting,
    ExamResultModel? submitResult,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      errorMessage: errorMessage,
      submitting: submitting ?? this.submitting,
      submitResult: submitResult,
    );
  }

  @override
  List<Object?> get props =>
      [status, quiz, errorMessage, submitting, submitResult];
}
