import 'package:equatable/equatable.dart';

import '../models/gamification_models.dart';

enum LeaderboardStatus { initial, loading, loaded, error }

class LeaderboardState extends Equatable {
  final LeaderboardStatus status;
  final List<LeaderboardEntry> entries;
  final bool weekly;
  final String? errorMessage;

  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.entries = const [],
    this.weekly = true,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<LeaderboardEntry>? entries,
    bool? weekly,
    String? errorMessage,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      weekly: weekly ?? this.weekly,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, weekly, errorMessage];
}
