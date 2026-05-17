import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_attendance_repository.dart';
import 'attendance_state.dart';

export 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final StudentAttendanceRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(minutes: 20);

  AttendanceCubit(this._repository) : super(const AttendanceState());

  Future<void> loadIfNeeded() async {
    if (state.status == AttendanceStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) return;

    final cached = _repository.getCached();
    if (cached != null) {
      if (state.status != AttendanceStatus.loaded) {
        emit(AttendanceState(status: AttendanceStatus.loaded, records: cached));
      }
      unawaited(_silentRefresh());
      return;
    }

    await loadAttendance();
  }

  Future<void> loadAttendance() async {
    emit(state.copyWith(status: AttendanceStatus.loading));
    try {
      final records = await _repository.fetchAttendanceRecords();
      emit(AttendanceState(status: AttendanceStatus.loaded, records: records));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStatus.error,
        errorMessage: 'Unable to load attendance records.',
      ));
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final records = await _repository.fetchAttendanceRecords();
      if (!isClosed) {
        emit(AttendanceState(status: AttendanceStatus.loaded, records: records));
        _lastLoadedAt = DateTime.now();
      }
    } catch (_) {}
  }
}
