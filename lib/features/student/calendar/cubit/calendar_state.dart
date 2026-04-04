import 'package:equatable/equatable.dart';
import '../models/calendar_event_model.dart';

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<CalendarEventModel> events;
  final DateTime selectedMonth;
  final String? errorMessage;

  CalendarState({
    this.status = CalendarStatus.initial,
    this.events = const [],
    DateTime? selectedMonth,
    this.errorMessage,
  }) : selectedMonth = selectedMonth ?? DateTime.now();

  CalendarState copyWith({
    CalendarStatus? status,
    List<CalendarEventModel>? events,
    DateTime? selectedMonth,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      events: events ?? this.events,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, selectedMonth, errorMessage];
}
