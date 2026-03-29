import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../models/calendar_event_model.dart';
import '../repositories/student_calendar_repository.dart';
import '../repositories/mock_student_calendar_repository.dart';

class StudentCalendarScreen extends StatefulWidget {
  final StudentCalendarRepository? repository;

  const StudentCalendarScreen({super.key, this.repository});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  late final StudentCalendarRepository _repository;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;
  List<CalendarEventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentCalendarRepository();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _repository.fetchEvents(month: _selectedDate);
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load calendar events.';
        _isLoading = false;
      });
    }
  }

  List<CalendarEventModel> get _eventsForDate =>
      _events.where((e) => _isSameDate(e.startTime, _selectedDate)).toList();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEventsOnDate(DateTime date) {
    return _events.any((e) => _isSameDate(e.startTime, date));
  }

  void _openEvent(CalendarEventModel event) {
    Navigator.of(context).pushNamed(
      RouteNames.studentCalendarEventDetail,
      arguments: {'eventId': event.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadEvents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                          final hasEvents = _hasEventsOnDate(day);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () =>
                                  setState(() => _selectedDate = day),
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
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    if (hasEvents && !isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final event = _eventsForDate[index];
                                final eventType = event.type.toLowerCase();
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(24),
                                    child: Icon(
                                      eventType == 'exam'
                                          ? Icons.rule_folder_outlined
                                          : eventType == 'class'
                                              ? Icons.menu_book_rounded
                                              : eventType == 'personal'
                                                  ? Icons.person_outlined
                                                  : Icons.event,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  title: Text(event.title),
                                  subtitle: Text(
                                    '${event.type} • ${event.location ?? 'No location'}',
                                  ),
                                  onTap: () => _openEvent(event),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
