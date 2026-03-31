import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_calendar_repository.dart';
import 'calendar_event_detail_state.dart';

export 'calendar_event_detail_state.dart';

class CalendarEventDetailCubit extends Cubit<CalendarEventDetailState> {
  final StudentCalendarRepository _repository;
  final String eventId;

  CalendarEventDetailCubit(this._repository, this.eventId)
      : super(const CalendarEventDetailState());

  Future<void> loadEvent() async {
    emit(state.copyWith(status: CalendarEventDetailStatus.loading));
    try {
      final event = await _repository.fetchEventById(eventId);
      emit(CalendarEventDetailState(
        status: CalendarEventDetailStatus.loaded,
        event: event,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CalendarEventDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
