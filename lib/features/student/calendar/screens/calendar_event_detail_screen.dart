import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event_model.dart';
import '../repositories/student_calendar_repository.dart';
import '../repositories/mock_student_calendar_repository.dart';

class CalendarEventDetailScreen extends StatefulWidget {
  final String eventId;
  final StudentCalendarRepository? repository;

  const CalendarEventDetailScreen({
    super.key,
    required this.eventId,
  }) : repository = null;

  @override
  State<CalendarEventDetailScreen> createState() => _CalendarEventDetailScreenState();
}

class _CalendarEventDetailScreenState extends State<CalendarEventDetailScreen> {
  late final StudentCalendarRepository _repo;
  CalendarEventModel? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockStudentCalendarRepository();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _event = await _repo.fetchEventById(widget.eventId);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'class':
        return Icons.class_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'personal':
        return Icons.person_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  Color _colorForType(String type, ThemeData theme) {
    switch (type) {
      case 'exam':
        return Colors.red;
      case 'class':
        return theme.colorScheme.primary;
      case 'event':
        return Colors.orange;
      case 'personal':
        return Colors.teal;
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final e = _event!;
    final color = _colorForType(e.type, theme);
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(e.type), color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(e.type.toUpperCase(), style: TextStyle(fontSize: 11, color: color)),
                      backgroundColor: color.withValues(alpha: 0.08),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: dateFormat.format(e.startTime),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: '${timeFormat.format(e.startTime)} - ${timeFormat.format(e.endTime)}',
          ),
          if (e.location != null) ...[
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: e.location!,
            ),
          ],
          if (e.description != null) ...[
            const Divider(height: 32),
            Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(e.description!, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
