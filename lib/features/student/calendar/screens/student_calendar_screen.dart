import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../cubit/calendar_cubit.dart';
import '../models/calendar_event_model.dart';
import '../repositories/student_calendar_repository.dart';

class StudentCalendarScreen extends StatelessWidget {
  const StudentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CalendarCubit(sl<StudentCalendarRepository>())..loadIfNeeded(),
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

  static const _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  List<CalendarEventModel> _eventsForDate(List<CalendarEventModel> events) =>
      events.where((e) => _isSameDate(e.startTime, _selectedDate)).toList();

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasEventsOnDate(List<CalendarEventModel> events, DateTime date) =>
      events.any((e) => _isSameDate(e.startTime, date));

  void _openEvent(CalendarEventModel event) {
    Navigator.of(context).pushNamed(
      RouteNames.studentCalendarEventDetail,
      arguments: {'eventId': event.id},
    );
  }

  List<DateTime?> _calendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sunday = 0

    final cells = <DateTime?>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: StudentPageBackground(
        child: BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, state) {
            final loading =
                state.status == CalendarStatus.initial ||
                state.status == CalendarStatus.loading;
            if (loading) {
              return const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(),
              );
            }
            if (state.status == CalendarStatus.error) {
              return AppErrorWidget(
                message:
                    state.errorMessage ?? 'Unable to load calendar events.',
                onRetry: () => context.read<CalendarCubit>().loadEvents(
                  month: state.selectedMonth,
                ),
              );
            }

            final events = state.events;
            final eventsForDate = _eventsForDate(events);
            final month = state.selectedMonth;
            final cells = _calendarDays(month);

            return Column(
              children: [
                // Month navigation header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            context.read<CalendarCubit>().previousMonth(),
                      ),
                      Text(
                        DateFormat.yMMMM().format(month),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () =>
                            context.read<CalendarCubit>().nextMonth(),
                      ),
                    ],
                  ),
                ),

                // Week day headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: _weekDays.map((d) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.gapXs,

                // Month grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                    itemCount: cells.length,
                    itemBuilder: (context, index) {
                      final day = cells[index];
                      if (day == null) return const SizedBox.shrink();

                      final isSelected = _isSameDate(day, _selectedDate);
                      final isToday = _isSameDate(day, today);
                      final hasEvents = _hasEventsOnDate(events, day);

                      return Pressable(
                        onTap: () => setState(() => _selectedDate = day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isToday
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.w600
                                      : null,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (hasEvents)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                AppSpacing.gapSm,

                // Event list for selected date
                Expanded(
                  child: BrandedRefreshIndicator(
                    onRefresh: () => context.read<CalendarCubit>().loadEvents(
                      month: state.selectedMonth,
                    ),
                    child: eventsForDate.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: const Center(
                                    child: EmptyStateWidget(
                                      illustration: CalendarIllustration(),
                                      icon: Icons.event_available_rounded,
                                      title: 'No events today',
                                      subtitle:
                                          'Nothing scheduled for this day. Enjoy!',
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: eventsForDate.length,
                            separatorBuilder: (_, _) => AppSpacing.gapMd,
                            itemBuilder: (context, index) {
                              final event = eventsForDate[index];
                              final eventType = event.type.toLowerCase();
                              void openEvent() => _openEvent(event);
                              return StaggeredFadeSlide(
                                index: index,
                                child: Pressable(
                                  onTap: openEvent,
                                  enableHaptic: false,
                                  child: ListTile(
                                    onTap: openEvent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.borderMd,
                                      side: BorderSide(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
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
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
