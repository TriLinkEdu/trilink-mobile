import 'package:flutter/material.dart';

class StudentAttendanceTile extends StatelessWidget {
  final String studentName;
  final bool isPresent;
  final ValueChanged<bool?>? onChanged;

  const StudentAttendanceTile({
    super.key,
    required this.studentName,
    required this.isPresent,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(studentName),
      value: isPresent,
      onChanged: onChanged,
    );
  }
}
