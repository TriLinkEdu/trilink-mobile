import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_calendar_repository.dart';
import 'calendar_event_detail_state.dart';

export 'calendar_event_detail_state.dart';

class CalendarEventDetailCubit extends Cubit<CalendarEventDetailState> {
  final StudentCalendarRepository _repository;
  final String eventId;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  CalendarEventDetailCubit(this._repository, this.eventId)
    : super(const CalendarEventDetailState());

  Future<void> loadIfNeeded() async {
    if (state.status == CalendarEventDetailStatus.loaded &&
        state.event?.id == eventId &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadEvent();
  }

  Future<void> loadEvent() async {
    emit(state.copyWith(status: CalendarEventDetailStatus.loading));
    try {
      final event = await _repository.fetchEventById(eventId);
      emit(
        CalendarEventDetailState(
          status: CalendarEventDetailStatus.loaded,
          event: event,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: CalendarEventDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
