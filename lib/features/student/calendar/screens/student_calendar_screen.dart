import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/calendar_cubit.dart';
import '../models/calendar_event_model.dart';
import '../repositories/student_calendar_repository.dart';

class StudentCalendarScreen extends StatelessWidget {
  const StudentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CalendarCubit(sl<StudentCalendarRepository>())..loadEvents(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _selectedDate = DateTime.now();

  List<CalendarEventModel> _eventsForDate(List<CalendarEventModel> events) =>
      events.where((e) => _isSameDate(e.startTime, _selectedDate)).toList();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEventsOnDate(List<CalendarEventModel> events, DateTime date) {
    return events.any((e) => _isSameDate(e.startTime, date));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          final loading = state.status == CalendarStatus.initial ||
              state.status == CalendarStatus.loading;
          if (loading) {
            return const Padding(
              padding: AppSpacing.paddingLg,
              child: ShimmerList(),
            );
          }
          if (state.status == CalendarStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ?? 'Unable to load calendar events.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  AppSpacing.gapMd,
                  ElevatedButton(
                    onPressed: () => context
                        .read<CalendarCubit>()
                        .loadEvents(month: _selectedDate),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final events = state.events;
          final eventsForDate = _eventsForDate(events);

          return Column(
            children: [
              AppSpacing.gapMd,
              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = today.add(Duration(days: index));
                    final isSelected = _isSameDate(day, _selectedDate);
                    final isToday = _isSameDate(day, today);
                    final hasEvents = _hasEventsOnDate(events, day);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: AppRadius.borderSm,
                        onTap: () =>
                            setState(() => _selectedDate = day),
                        child: Container(
                          width: 58,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isToday
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                            borderRadius: AppRadius.borderSm,
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
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (hasEvents && !isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
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
              AppSpacing.gapSm,
              Expanded(
                child: eventsForDate.isEmpty
                    ? Center(
                        child: Text(
                          'No scheduled items for this day.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: eventsForDate.length,
                        separatorBuilder: (_, __) =>
                            AppSpacing.gapMd,
                        itemBuilder: (context, index) {
                          final event = eventsForDate[index];
                          final eventType = event.type.toLowerCase();
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMd,
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(24),
                              child: Icon(
                                eventType == 'exam'
                                    ? Icons.rule_folder_outlined
                                    : eventType == 'class'
                                        ? Icons.menu_book_rounded
                                        : eventType == 'personal'
                                            ? Icons.person_outlined
                                            : Icons.event,
                                color: theme.colorScheme.primary,
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
          );
        },
      ),
    );
  }
}
