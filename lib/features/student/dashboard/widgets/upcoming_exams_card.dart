import 'package:flutter/material.dart';

class UpcomingExamsCard extends StatelessWidget {
  final List<_ExamItem> exams;

  const UpcomingExamsCard({super.key, this.exams = const []});

  @override
  Widget build(BuildContext context) {
    const defaultExams = [
      _ExamItem(subject: 'Physics', date: 'Mar 25', time: '9:00 AM'),
      _ExamItem(subject: 'Mathematics', date: 'Mar 27', time: '1:30 PM'),
    ];
    final upcoming = exams.isEmpty ? defaultExams : exams;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Exams',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...List.generate(upcoming.length, (index) {
              final exam = upcoming[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == upcoming.length - 1 ? 0 : 8),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(exam.subject)),
                    Text('${exam.date} • ${exam.time}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ExamItem {
  final String subject;
  final String date;
  final String time;

  const _ExamItem({
    required this.subject,
    required this.date,
    required this.time,
  });
}
