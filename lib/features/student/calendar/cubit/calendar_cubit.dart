import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_calendar_repository.dart';
import 'calendar_state.dart';

export 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final StudentCalendarRepository _repository;

  CalendarCubit(this._repository) : super(const CalendarState());

  Future<void> loadEvents({DateTime? month}) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    try {
      final events = await _repository.fetchEvents(
        month: month ?? DateTime.now(),
      );
      emit(CalendarState(status: CalendarStatus.loaded, events: events));
    } catch (_) {
      emit(state.copyWith(
        status: CalendarStatus.error,
        errorMessage: 'Unable to load calendar events.',
      ));
    }
  }
}
