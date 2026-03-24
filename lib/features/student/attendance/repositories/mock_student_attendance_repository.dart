import '../models/attendance_model.dart';
import 'student_attendance_repository.dart';

class MockStudentAttendanceRepository implements StudentAttendanceRepository {
  static const Duration _latency = Duration(milliseconds: 280);

  @override
  Future<List<AttendanceModel>> fetchAttendanceRecords() async {
    await Future<void>.delayed(_latency);

    final records = <AttendanceModel>[];
    records.addAll(_subjectRecords('math', 'Mathematics', 24, 22));
    records.addAll(_subjectRecords('physics', 'Physics', 20, 19));
    records.addAll(_subjectRecords('literature', 'English Literature', 18, 18));
    return records;
  }

  List<AttendanceModel> _subjectRecords(
    String subjectId,
    String subjectName,
    int total,
    int present,
  ) {
    return List<AttendanceModel>.generate(total, (index) {
      return AttendanceModel(
        id: '$subjectId-$index',
        subjectId: subjectId,
        subjectName: subjectName,
        date: DateTime(2023, 9, 1).add(Duration(days: index)),
        isPresent: index < present,
      );
    });
  }
}
