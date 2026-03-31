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
      emit(FeedbackState(
        status: FeedbackStatus.loaded,
        feedbackHistory: history,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: FeedbackStatus.error,
        errorMessage: 'Unable to load feedback history.',
      ));
    }
  }
}
