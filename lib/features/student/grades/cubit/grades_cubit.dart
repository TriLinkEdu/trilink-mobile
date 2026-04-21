import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_grades_repository.dart';
import 'grades_state.dart';

export 'grades_state.dart';

class GradesCubit extends Cubit<GradesState> {
  final StudentGradesRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  GradesCubit(this._repository) : super(const GradesState());

  Future<void> loadIfNeeded({String? term}) async {
    final selectedTerm = term ?? state.selectedTerm;
    if (state.status == GradesStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl &&
        selectedTerm == state.selectedTerm) {
      return;
    }
    await loadGrades(term: selectedTerm);
  }

  Future<void> loadGrades({String? term}) async {
    final selectedTerm = term ?? state.selectedTerm;
    emit(
      state.copyWith(status: GradesStatus.loading, selectedTerm: selectedTerm),
    );
    try {
      final grades = await _repository.fetchGrades(term: selectedTerm);
      emit(state.copyWith(status: GradesStatus.loaded, grades: grades));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(status: GradesStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void switchTerm(String term) {
    loadGrades(term: term);
  }
}
