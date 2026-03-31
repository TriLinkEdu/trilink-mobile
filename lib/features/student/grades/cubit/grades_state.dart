import 'package:equatable/equatable.dart';
import '../models/grade_model.dart';

enum GradesStatus { initial, loading, loaded, error }

class GradesState extends Equatable {
  final GradesStatus status;
  final List<GradeModel> grades;
  final String selectedTerm;
  final String? errorMessage;

  const GradesState({
    this.status = GradesStatus.initial,
    this.grades = const [],
    this.selectedTerm = 'Fall 2023',
    this.errorMessage,
  });

  GradesState copyWith({
    GradesStatus? status,
    List<GradeModel>? grades,
    String? selectedTerm,
    String? errorMessage,
  }) {
    return GradesState(
      status: status ?? this.status,
      grades: grades ?? this.grades,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, grades, selectedTerm, errorMessage];
}
