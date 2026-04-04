import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_feedback_repository.dart';
import 'feedback_state.dart';

export 'feedback_state.dart';

class FeedbackCubit extends Cubit<FeedbackState> {
  final StudentFeedbackRepository _repository;

  FeedbackCubit(this._repository) : super(const FeedbackState());

  Future<void> loadFeedbackHistory() async {
    emit(state.copyWith(status: FeedbackStatus.loading));
    try {
      final history = await _repository.fetchFeedbackHistory();
      emit(
        state.copyWith(
          status: FeedbackStatus.loaded,
          feedbackHistory: history,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FeedbackStatus.error,
          errorMessage: 'Unable to load feedback history: $e',
        ),
      );
    }
  }

  Future<void> submitFeedback({
    required String subjectId,
    required String subjectName,
    required int rating,
    String? comment,
  }) async {
    emit(
      state.copyWith(
        submissionStatus: FeedbackSubmissionStatus.submitting,
        submissionErrorMessage: null,
      ),
    );
    try {
      await _repository.submitFeedback(
        subjectId: subjectId,
        subjectName: subjectName,
        rating: rating,
        comment: comment,
      );
      emit(state.copyWith(submissionStatus: FeedbackSubmissionStatus.success));
      await loadFeedbackHistory();
    } catch (e) {
      emit(
        state.copyWith(
          submissionStatus: FeedbackSubmissionStatus.error,
          submissionErrorMessage: 'Failed to submit feedback: $e',
        ),
      );
    }
  }

  void clearSubmissionStatus() {
    emit(
      state.copyWith(
        submissionStatus: FeedbackSubmissionStatus.idle,
        submissionErrorMessage: null,
      ),
    );
  }
}
