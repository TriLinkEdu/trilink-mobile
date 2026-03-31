import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_attendance_repository.dart';
import 'attendance_state.dart';

export 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final StudentAttendanceRepository _repository;

  AttendanceCubit(this._repository) : super(const AttendanceState());

  Future<void> loadAttendance() async {
    emit(state.copyWith(status: AttendanceStatus.loading));
    try {
      final records = await _repository.fetchAttendanceRecords();
      emit(AttendanceState(status: AttendanceStatus.loaded, records: records));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStatus.error,
        errorMessage: 'Unable to load attendance records.',
      ));
    }
  }
}
