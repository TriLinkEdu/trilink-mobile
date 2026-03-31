import 'package:equatable/equatable.dart';
import '../models/feedback_model.dart';

enum FeedbackStatus { initial, loading, loaded, error }

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final List<FeedbackModel> feedbackHistory;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.feedbackHistory = const [],
    this.errorMessage,
  });

  FeedbackState copyWith({
    FeedbackStatus? status,
    List<FeedbackModel>? feedbackHistory,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      feedbackHistory: feedbackHistory ?? this.feedbackHistory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, feedbackHistory, errorMessage];
}
