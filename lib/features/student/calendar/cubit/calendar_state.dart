import 'package:equatable/equatable.dart';
import '../models/calendar_event_model.dart';

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<CalendarEventModel> events;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  CalendarState copyWith({
    CalendarStatus? status,
    List<CalendarEventModel>? events,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
