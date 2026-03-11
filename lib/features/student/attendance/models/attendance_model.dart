class AttendanceModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final bool isPresent;

  const AttendanceModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.isPresent,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      date: DateTime.parse(json['date'] as String),
      isPresent: json['isPresent'] as bool,
    );
  }
}
