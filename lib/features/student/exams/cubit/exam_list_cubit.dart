import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exam_model.dart';
import '../repositories/student_exams_repository.dart';

// ── State ──

enum ExamListStatus { initial, loading, loaded, error }

class ExamListState extends Equatable {
  final ExamListStatus status;
  final List<ExamModel> exams;
  final String? errorMessage;

  const ExamListState({
    this.status = ExamListStatus.initial,
    this.exams = const [],
    this.errorMessage,
  });

  ExamListState copyWith({
    ExamListStatus? status,
    List<ExamModel>? exams,
    String? errorMessage,
  }) {
    return ExamListState(
      status: status ?? this.status,
      exams: exams ?? this.exams,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, exams, errorMessage];
}

// ── Cubit ──

class ExamListCubit extends Cubit<ExamListState> {
  final StudentExamsRepository _repository;

  ExamListCubit(this._repository) : super(const ExamListState());

  Future<void> loadExams() async {
    emit(state.copyWith(status: ExamListStatus.loading));
    try {
      final exams = await _repository.fetchAvailableExams();
      emit(ExamListState(status: ExamListStatus.loaded, exams: exams));
    } catch (e) {
      emit(
        state.copyWith(
          status: ExamListStatus.error,
          errorMessage: 'Unable to load exams: $e',
        ),
      );
    }
  }
}
