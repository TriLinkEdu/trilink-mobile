import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class TeacherCalendarScreen extends StatefulWidget {
  const TeacherCalendarScreen({super.key});

  @override
  State<TeacherCalendarScreen> createState() => _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends State<TeacherCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  bool _loading = true;
  String? _error;
  List<_CalendarEvent> _allEvents = [];

  List<int> get _daysWithEvents {
    final days = <int>{};
    for (final e in _allEvents) {
      if (e.date != null &&
          e.date!.year == _currentMonth.year &&
          e.date!.month == _currentMonth.month) {
        days.add(e.date!.day);
      }
    }
    return days.toList();
  }

  List<_CalendarEvent> get _eventsForSelectedDay {
    return _allEvents.where((e) {
      if (e.date == null) return false;
      return e.date!.year == _currentMonth.year &&
          e.date!.month == _currentMonth.month &&
          e.date!.day == _selectedDay;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Get current month date range
      final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
      
      final from = '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
      final to = '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';
      
      final raw = await ApiService().getCalendarEvents(
        from: from,
        to: to,
      );
      
      setState(() {
        _allEvents = raw
            .map((e) => _CalendarEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = 1;
    });
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = 'Lecture';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Event title',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: 'Location',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Type',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedType,
                                    isExpanded: true,
                                    items:
                                        [
                                              'Lecture',
                                              'Meeting',
                                              'Availability',
                                              'Exam',
                                              'Other',
                                            ]
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) {
                                      setSheetState(() => selectedType = v!);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: startTime,
                                  );
                                  if (picked != null) {
                                    setSheetState(() => startTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    startTime.format(ctx),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (titleController.text.trim().isEmpty) {
                                  return;
                                }
                                setSheetState(() => submitting = true);
                                try {
                                  final eventDate = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month,
                                    _selectedDay,
                                  );
                                  
                                  // Format date as YYYY-MM-DD
                                  final dateStr = '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
                                  
                                  // Format time as HH:MM
                                  final timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                                  
                                  await ApiService().createCalendarEvent({
                                    'title': titleController.text.trim(),
                                    'date': dateStr,
                                    'time': timeStr,
                                    'type': selectedType.toLowerCase(),
                                    'description': locationController.text.trim(),
                                  });
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _loadData();
                                } catch (e) {
                                  setSheetState(() => submitting = false);
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Add Event',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildMonthNavigation(),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(),
                  const Divider(height: 32),
                  Expanded(child: _buildEventsList()),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/80?img=32'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final theme = Theme.of(context);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Text(
            '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _nextMonth,
            child: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final theme = Theme.of(context);
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;

    final previousMonthDays = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;

    final eventDays = _daysWithEvents;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: daysOfWeek
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(((startWeekday + daysInMonth) / 7).ceil(), (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: List.generate(7, (day) {
                  final cellIndex = week * 7 + day;
                  final dayNum = cellIndex - startWeekday + 1;

                  if (dayNum < 1) {
                    final prevDay = previousMonthDays + dayNum;
                    return _buildDayCell(prevDay, isOtherMonth: true);
                  }
                  if (dayNum > daysInMonth) {
                    return _buildDayCell(
                      dayNum - daysInMonth,
                      isOtherMonth: true,
                    );
                  }
                  return _buildDayCell(
                    dayNum,
                    isSelected: dayNum == _selectedDay,
                    hasEvent: eventDays.contains(dayNum),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    int day, {
    bool isSelected = false,
    bool isOtherMonth = false,
    bool hasEvent = false,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: isOtherMonth ? null : () => setState(() => _selectedDay = day),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isOtherMonth
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (hasEvent && !isSelected)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final theme = Theme.of(context);
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final selectedDate = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      _selectedDay,
    );
    final dayName = dayNames[(selectedDate.weekday - 1) % 7];
    final monthName = monthNames[selectedDate.month - 1];

    final events = _eventsForSelectedDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dayName, $monthName $_selectedDay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${events.length} Events',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No events for this day',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...events.map((e) => _EventCard(event: e)),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  final String time;
  final String title;
  final String type;
  final Color typeColor;
  final String duration;
  final String location;
  final DateTime? date;

  _CalendarEvent({
    required this.time,
    required this.title,
    required this.type,
    required this.typeColor,
    required this.duration,
    required this.location,
    this.date,
  });

  factory _CalendarEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'other';
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'class':
      case 'lecture':
        typeColor = AppColors.primary;
        break;
      case 'exam':
        typeColor = AppColors.error;
        break;
      case 'meeting':
        typeColor = Colors.purple;
        break;
      case 'holiday':
        typeColor = AppColors.secondary;
        break;
      default:
        typeColor = AppColors.accent;
    }

    DateTime? parsedDate;
    final dateStr = json['date'] as String?;
    final timeStr = json['time'] as String?;
    
    if (dateStr != null && dateStr.isNotEmpty) {
      if (timeStr != null && timeStr.isNotEmpty) {
        // Combine date and time: YYYY-MM-DD + HH:MM
        parsedDate = DateTime.tryParse('$dateStr $timeStr:00');
      } else {
        parsedDate = DateTime.tryParse(dateStr);
      }
    }

    String displayTime = '';
    if (parsedDate != null) {
      final h = parsedDate.hour;
      final m = parsedDate.minute;
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      displayTime =
          '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    }

    return _CalendarEvent(
      time: displayTime,
      title: json['title'] ?? '',
      type: type[0].toUpperCase() + type.substring(1),
      typeColor: typeColor,
      duration: '', // Backend doesn't provide duration
      location: json['description'] ?? '',
      date: parsedDate,
    );
  }
}

class _EventCard extends StatelessWidget {
  final _CalendarEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              event.time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 80,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: event.typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: event.typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: event.typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (event.duration.isNotEmpty) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (event.location.isNotEmpty) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
