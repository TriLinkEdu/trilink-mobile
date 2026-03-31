import '../models/attendance_model.dart';

abstract class StudentAttendanceRepository {
  Future<List<AttendanceModel>> fetchAttendanceRecords();
}
