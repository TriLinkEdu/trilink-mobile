import 'package:equatable/equatable.dart';
import '../models/grade_model.dart';

enum GradesStatus { initial, loading, loaded, error }

class GradesState extends Equatable {
  final GradesStatus status;
  final List<GradeModel> grades;
  final String selectedTerm;
  final List<String> availableTerms;
  final String? errorMessage;

  const GradesState({
    this.status = GradesStatus.initial,
    this.grades = const [],
    this.selectedTerm = '',   // empty until derived from live data
    this.availableTerms = const [],
    this.errorMessage,
  });

  GradesState copyWith({
    GradesStatus? status,
    List<GradeModel>? grades,
    String? selectedTerm,
    List<String>? availableTerms,
    String? errorMessage,
  }) {
    return GradesState(
      status: status ?? this.status,
      grades: grades ?? this.grades,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      availableTerms: availableTerms ?? this.availableTerms,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, grades, selectedTerm, availableTerms, errorMessage];
}
