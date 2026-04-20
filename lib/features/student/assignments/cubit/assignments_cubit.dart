import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_assignments_repository.dart';
import 'assignments_state.dart';

export 'assignments_state.dart';

class AssignmentsCubit extends Cubit<AssignmentsState> {
  final StudentAssignmentsRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  AssignmentsCubit(this._repository) : super(const AssignmentsState());

  Future<void> loadIfNeeded() async {
    if (state.status == AssignmentsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadAssignments();
  }

  Future<void> loadAssignments() async {
    emit(state.copyWith(status: AssignmentsStatus.loading));
    try {
      final assignments = await _repository.fetchAssignments();
      emit(
        AssignmentsState(
          status: AssignmentsStatus.loaded,
          assignments: assignments,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: AssignmentsStatus.error,
          errorMessage: 'Unable to load assignments: $e',
        ),
      );
    }
  }
}
