enum AttendanceStatus { present, absent, late, excused }

class AttendanceModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final AttendanceStatus status;

  const AttendanceModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.status,
  });

  bool get isPresent => status == AttendanceStatus.present;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => json['isPresent'] == true
            ? AttendanceStatus.present
            : AttendanceStatus.absent,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'date': date.toIso8601String(),
        'status': status.name,
      };
}
