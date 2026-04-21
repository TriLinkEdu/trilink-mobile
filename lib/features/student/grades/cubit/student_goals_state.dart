import 'package:equatable/equatable.dart';

import '../../../../core/models/student_goal_model.dart';
import '../../../../core/models/performance_report_model.dart';
import '../../../../core/models/topic_mastery_model.dart';

enum StudentGoalsStatus { initial, loading, loaded, error }

class StudentGoalsState extends Equatable {
  final StudentGoalsStatus status;
  final List<StudentGoalModel> goals;
  final PerformanceReportModel? report;
  final List<TopicMasteryModel> mastery;
  final String? errorMessage;
  final bool isSaving;

  const StudentGoalsState({
    this.status = StudentGoalsStatus.initial,
    this.goals = const [],
    this.report,
    this.mastery = const [],
    this.errorMessage,
    this.isSaving = false,
  });

  StudentGoalsState copyWith({
    StudentGoalsStatus? status,
    List<StudentGoalModel>? goals,
    PerformanceReportModel? report,
    bool clearReport = false,
    List<TopicMasteryModel>? mastery,
    String? errorMessage,
    bool clearError = false,
    bool? isSaving,
  }) {
    return StudentGoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      report: clearReport ? null : (report ?? this.report),
      mastery: mastery ?? this.mastery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
    status,
    goals,
    report,
    mastery,
    errorMessage,
    isSaving,
  ];
}
