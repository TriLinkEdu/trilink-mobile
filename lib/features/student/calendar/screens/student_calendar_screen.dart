import 'package:flutter/material.dart';

/// School events, exams, and personal schedule.
class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<_CalendarEvent> _events = [
    _CalendarEvent(
      date: DateTime(2026, 3, 25),
      title: 'Physics Quiz',
      subtitle: 'Room B-12 • 9:00 AM',
      type: 'Exam',
    ),
    _CalendarEvent(
      date: DateTime(2026, 3, 26),
      title: 'Chemistry Lab',
      subtitle: 'Lab 2 • 1:30 PM',
      type: 'Class',
    ),
    _CalendarEvent(
      date: DateTime(2026, 3, 28),
      title: 'Science Fair Orientation',
      subtitle: 'Auditorium • 11:00 AM',
      type: 'Event',
    ),
  ];

  List<_CalendarEvent> get _eventsForDate =>
      _events.where((e) => _isSameDate(e.date, _selectedDate)).toList();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = today.add(Duration(days: index));
                final isSelected = _isSameDate(day, _selectedDate);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedDate = day),
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                [day.weekday - 1],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _eventsForDate.isEmpty
                ? const Center(
                    child: Text(
                      'No scheduled items for this day.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _eventsForDate.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = _eventsForDate[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withAlpha(24),
                          child: Icon(
                            event.type == 'Exam'
                                ? Icons.rule_folder_outlined
                                : event.type == 'Class'
                                    ? Icons.menu_book_rounded
                                    : Icons.event,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(event.title),
                        subtitle: Text('${event.type} • ${event.subtitle}'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opened ${event.title}')),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  final DateTime date;
  final String title;
  final String subtitle;
  final String type;

  const _CalendarEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}
