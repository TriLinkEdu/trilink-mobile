import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/student_goal_model.dart';
import '../repositories/student_performance_repository.dart';
import 'student_goals_state.dart';

class StudentGoalsCubit extends Cubit<StudentGoalsState> {
  final StudentPerformanceRepository _repository;

  StudentGoalsCubit(this._repository) : super(const StudentGoalsState());

  Future<void> load(String studentId) async {
    emit(state.copyWith(status: StudentGoalsStatus.loading, clearError: true));
    try {
      final goals = await _repository.fetchGoals(studentId);
      final report = await _repository.fetchLatestReport(studentId);
      final mastery = await _repository.fetchMasteryLevels(studentId);

      emit(
        state.copyWith(
          status: StudentGoalsStatus.loaded,
          goals: goals,
          report: report,
          mastery: mastery,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StudentGoalsStatus.error,
          errorMessage: 'Unable to load goals and performance: $e',
        ),
      );
    }
  }

  Future<bool> createGoal({
    required String studentId,
    required String text,
    DateTime? targetDate,
  }) async {
    if (text.trim().isEmpty) return false;
    if (text.trim().length > 200) {
      emit(
        state.copyWith(
          errorMessage: 'Goal text must be 200 characters or fewer.',
        ),
      );
      return false;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _repository.createGoal(
        StudentGoalModel(
          id: '',
          studentId: studentId,
          goalText: text.trim(),
          targetDate: targetDate,
          createdAt: DateTime.now(),
        ),
      );

      emit(state.copyWith(isSaving: false));
      await load(studentId);
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to create goal: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> toggleGoalCompletion(StudentGoalModel goal) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final next = goal.copyWith(isAchieved: !goal.isAchieved);
    try {
      final saved = await _repository.updateGoal(next);
      emit(state.copyWith(isSaving: false));
      await load(saved.studentId);
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to update goal: $e',
        ),
      );
      return false;
    }
  }
}
