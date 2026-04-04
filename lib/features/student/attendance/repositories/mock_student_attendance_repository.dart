import '../models/attendance_model.dart';
import 'student_attendance_repository.dart';

class MockStudentAttendanceRepository implements StudentAttendanceRepository {
  static const Duration _latency = Duration(milliseconds: 280);

  @override
  Future<List<AttendanceModel>> fetchAttendanceRecords() async {
    await Future<void>.delayed(_latency);

    final records = <AttendanceModel>[];
    records.addAll(_subjectRecords('math', 'Mathematics', 24, 20, 2, 1));
    records.addAll(_subjectRecords('physics', 'Physics', 20, 17, 2, 1));
    records.addAll(
      _subjectRecords('literature', 'English Literature', 18, 14, 2, 1),
    );
    return records;
  }

  List<AttendanceModel> _subjectRecords(
    String subjectId,
    String subjectName,
    int total,
    int presentCount,
    int lateCount,
    int excusedCount,
  ) {
    return List<AttendanceModel>.generate(total, (index) {
      AttendanceStatus status;
      if (index < presentCount) {
        status = AttendanceStatus.present;
      } else if (index < presentCount + lateCount) {
        status = AttendanceStatus.late;
      } else if (index < presentCount + lateCount + excusedCount) {
        status = AttendanceStatus.excused;
      } else {
        status = AttendanceStatus.absent;
      }
      return AttendanceModel(
        id: '$subjectId-$index',
        subjectId: subjectId,
        subjectName: subjectName,
        date: DateTime(2023, 9, 1).add(Duration(days: index)),
        status: status,
      );
    });
  }
}
