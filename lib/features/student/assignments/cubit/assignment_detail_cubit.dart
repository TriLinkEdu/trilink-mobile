import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_assignments_repository.dart';
import 'assignment_detail_state.dart';

export 'assignment_detail_state.dart';

class AssignmentDetailCubit extends Cubit<AssignmentDetailState> {
  final StudentAssignmentsRepository _repository;
  final String assignmentId;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  AssignmentDetailCubit(this._repository, this.assignmentId)
    : super(const AssignmentDetailState());

  Future<void> loadIfNeeded() async {
    if (state.status == AssignmentDetailStatus.loaded &&
        state.assignment?.id == assignmentId &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadAssignment();
  }

  Future<void> loadAssignment() async {
    emit(state.copyWith(status: AssignmentDetailStatus.loading));
    try {
      final assignment = await _repository.fetchAssignmentById(assignmentId);
      emit(
        AssignmentDetailState(
          status: AssignmentDetailStatus.loaded,
          assignment: assignment,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: AssignmentDetailStatus.error,
          errorMessage: 'Could not load assignment details: $e',
        ),
      );
    }
  }

  Future<void> submit(String content) async {
    final current = state.assignment;
    if (current == null) return;

    emit(state.copyWith(isSubmitting: true, submitError: null));
    try {
      await _repository.submitAssignment(current.id, content);
      final refreshed = await _repository.fetchAssignmentById(current.id);
      emit(
        state.copyWith(
          status: AssignmentDetailStatus.loaded,
          assignment: refreshed,
          isSubmitting: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: 'Failed to submit assignment: $e',
        ),
      );
    }
  }
}
