import 'package:equatable/equatable.dart';
import '../models/attendance_model.dart' hide AttendanceStatus;

enum AttendanceStatus { initial, loading, loaded, error }

class AttendanceState extends Equatable {
  final AttendanceStatus status;
  final List<AttendanceModel> records;
  final String? errorMessage;

  const AttendanceState({
    this.status = AttendanceStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  AttendanceState copyWith({
    AttendanceStatus? status,
    List<AttendanceModel>? records,
    String? errorMessage,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, errorMessage];
}
