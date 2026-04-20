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

  Future<void> createGoal({
    required String studentId,
    required String text,
    DateTime? targetDate,
  }) async {
    if (state.isSaving) return;
    if (text.trim().isEmpty) return;
    if (text.trim().length > 200) {
      emit(
        state.copyWith(
          errorMessage: 'Goal text must be 200 characters or fewer.',
        ),
      );
      return;
    }

    final now = DateTime.now();
    final optimistic = StudentGoalModel(
      id: 'local-${now.microsecondsSinceEpoch}',
      studentId: studentId,
      goalText: text.trim(),
      targetDate: targetDate,
      createdAt: now,
      isAchieved: false,
    );

    emit(
      state.copyWith(
        goals: [optimistic, ...state.goals],
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final created = await _repository.createGoal(
        StudentGoalModel(
          id: '',
          studentId: studentId,
          goalText: text.trim(),
          targetDate: targetDate,
          createdAt: DateTime.now(),
        ),
      );

      final updated = state.goals
          .map((g) => g.id == optimistic.id ? created : g)
          .toList();
      emit(state.copyWith(goals: updated, isSaving: false));
    } catch (e) {
      final reverted = state.goals.where((g) => g.id != optimistic.id).toList();
      emit(
        state.copyWith(
          goals: reverted,
          isSaving: false,
          errorMessage: 'Failed to create goal: $e',
        ),
      );
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
