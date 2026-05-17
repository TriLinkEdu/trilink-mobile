import 'package:equatable/equatable.dart';
import '../../../../core/models/student_goal_model.dart';

enum YearlyPlannerStatus { initial, loading, loaded, error }

class TermProgress extends Equatable {
  final String id;
  final String name;
  final String dateRange;
  final double avgScore;
  final double attendanceRate;
  final int goalsHit;
  final int goalsTotal;

  const TermProgress({
    required this.id,
    required this.name,
    required this.dateRange,
    required this.avgScore,
    required this.attendanceRate,
    required this.goalsHit,
    required this.goalsTotal,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        dateRange,
        avgScore,
        attendanceRate,
        goalsHit,
        goalsTotal,
      ];
}

class YearlyPlannerState extends Equatable {
  final YearlyPlannerStatus status;
  final String academicYear;
  final double overallScore;
  final double attendanceRate;
  final int totalXp;
  final int goalsCompleted;
  final int goalsTotal;
  final List<TermProgress> terms;
  final int currentTermIndex;
  final List<StudentGoalModel> activeGoals;
  final String? errorMessage;

  const YearlyPlannerState({
    this.status = YearlyPlannerStatus.initial,
    this.academicYear = '',
    this.overallScore = 0.0,
    this.attendanceRate = 0.0,
    this.totalXp = 0,
    this.goalsCompleted = 0,
    this.goalsTotal = 0,
    this.terms = const [],
    this.currentTermIndex = 0,
    this.activeGoals = const [],
    this.errorMessage,
  });

  YearlyPlannerState copyWith({
    YearlyPlannerStatus? status,
    String? academicYear,
    double? overallScore,
    double? attendanceRate,
    int? totalXp,
    int? goalsCompleted,
    int? goalsTotal,
    List<TermProgress>? terms,
    int? currentTermIndex,
    List<StudentGoalModel>? activeGoals,
    String? errorMessage,
    bool clearError = false,
  }) {
    return YearlyPlannerState(
      status: status ?? this.status,
      academicYear: academicYear ?? this.academicYear,
      overallScore: overallScore ?? this.overallScore,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      totalXp: totalXp ?? this.totalXp,
      goalsCompleted: goalsCompleted ?? this.goalsCompleted,
      goalsTotal: goalsTotal ?? this.goalsTotal,
      terms: terms ?? this.terms,
      currentTermIndex: currentTermIndex ?? this.currentTermIndex,
      activeGoals: activeGoals ?? this.activeGoals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        academicYear,
        overallScore,
        attendanceRate,
        totalXp,
        goalsCompleted,
        goalsTotal,
        terms,
        currentTermIndex,
        activeGoals,
        errorMessage,
      ];
}
