import 'package:equatable/equatable.dart';
import '../models/feedback_model.dart';

enum FeedbackStatus { initial, loading, loaded, error }

enum FeedbackSubmissionStatus { idle, submitting, success, error }

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final List<FeedbackModel> feedbackHistory;
  final String? errorMessage;
  final FeedbackSubmissionStatus submissionStatus;
  final String? submissionErrorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.feedbackHistory = const [],
    this.errorMessage,
    this.submissionStatus = FeedbackSubmissionStatus.idle,
    this.submissionErrorMessage,
  });

  FeedbackState copyWith({
    FeedbackStatus? status,
    List<FeedbackModel>? feedbackHistory,
    String? errorMessage,
    FeedbackSubmissionStatus? submissionStatus,
    String? submissionErrorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      feedbackHistory: feedbackHistory ?? this.feedbackHistory,
      errorMessage: errorMessage,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionErrorMessage: submissionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    feedbackHistory,
    errorMessage,
    submissionStatus,
    submissionErrorMessage,
  ];
}
