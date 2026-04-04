import 'package:equatable/equatable.dart';

import '../../exams/models/exam_model.dart';

enum QuizLoadStatus { initial, loading, loaded, error }

class QuizState extends Equatable {
  final QuizLoadStatus status;
  final ExamModel? quiz;
  final String? errorMessage;
  final bool submitting;
  final ExamResultModel? submitResult;
  final List<String> newlyUnlockedAchievements;
  final bool leveledUp;
  final int? newLevel;

  const QuizState({
    this.status = QuizLoadStatus.initial,
    this.quiz,
    this.errorMessage,
    this.submitting = false,
    this.submitResult,
    this.newlyUnlockedAchievements = const [],
    this.leveledUp = false,
    this.newLevel,
  });

  QuizState copyWith({
    QuizLoadStatus? status,
    ExamModel? quiz,
    String? errorMessage,
    bool? submitting,
    ExamResultModel? submitResult,
    List<String>? newlyUnlockedAchievements,
    bool? leveledUp,
    int? newLevel,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      errorMessage: errorMessage,
      submitting: submitting ?? this.submitting,
      submitResult: submitResult,
      newlyUnlockedAchievements:
          newlyUnlockedAchievements ?? this.newlyUnlockedAchievements,
      leveledUp: leveledUp ?? this.leveledUp,
      newLevel: newLevel ?? this.newLevel,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quiz,
    errorMessage,
    submitting,
    submitResult,
    newlyUnlockedAchievements,
    leveledUp,
    newLevel,
  ];
}
