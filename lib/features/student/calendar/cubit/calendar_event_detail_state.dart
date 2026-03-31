import 'package:equatable/equatable.dart';
import '../models/calendar_event_model.dart';

enum CalendarEventDetailStatus { initial, loading, loaded, error }

class CalendarEventDetailState extends Equatable {
  final CalendarEventDetailStatus status;
  final CalendarEventModel? event;
  final String? errorMessage;

  const CalendarEventDetailState({
    this.status = CalendarEventDetailStatus.initial,
    this.event,
    this.errorMessage,
  });

  CalendarEventDetailState copyWith({
    CalendarEventDetailStatus? status,
    CalendarEventModel? event,
    String? errorMessage,
  }) {
    return CalendarEventDetailState(
      status: status ?? this.status,
      event: event ?? this.event,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, event, errorMessage];
}
