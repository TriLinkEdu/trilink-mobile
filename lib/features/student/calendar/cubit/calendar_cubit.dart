import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_calendar_repository.dart';
import 'calendar_state.dart';

export 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final StudentCalendarRepository _repository;

  CalendarCubit(this._repository) : super(CalendarState());

  Future<void> loadEvents({DateTime? month}) async {
    final target = month ?? state.selectedMonth;
    emit(state.copyWith(status: CalendarStatus.loading, selectedMonth: target));
    try {
      final events = await _repository.fetchEvents(month: target);
      emit(state.copyWith(status: CalendarStatus.loaded, events: events));
    } catch (e) {
      emit(
        state.copyWith(
          status: CalendarStatus.error,
          errorMessage: 'Unable to load calendar events: $e',
        ),
      );
    }
  }

  void changeMonth(DateTime month) {
    loadEvents(month: month);
  }

  void previousMonth() {
    final m = state.selectedMonth;
    changeMonth(DateTime(m.year, m.month - 1));
  }

  void nextMonth() {
    final m = state.selectedMonth;
    changeMonth(DateTime(m.year, m.month + 1));
  }
}
