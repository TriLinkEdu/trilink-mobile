import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/calendar_event_detail_cubit.dart';
import '../models/calendar_event_model.dart';
import '../repositories/student_calendar_repository.dart';

class CalendarEventDetailScreen extends StatelessWidget {
  final String eventId;

  const CalendarEventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarEventDetailCubit(
        sl<StudentCalendarRepository>(),
        eventId,
      )..loadEvent(),
      child: const _CalendarEventDetailView(),
    );
  }
}

class _CalendarEventDetailView extends StatelessWidget {
  const _CalendarEventDetailView();

  static IconData _iconForType(String type) {
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

  static Color _colorForType(String type, ThemeData theme) {
    switch (type) {
      case 'exam':
        return AppColors.danger;
      case 'class':
        return theme.colorScheme.primary;
      case 'event':
        return AppColors.warning;
      case 'personal':
        return AppColors.secondary;
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details'), centerTitle: true),
      body: BlocBuilder<CalendarEventDetailCubit, CalendarEventDetailState>(
        builder: (context, state) {
          if (state.status == CalendarEventDetailStatus.initial ||
              state.status == CalendarEventDetailStatus.loading) {
            return const Padding(
              padding: AppSpacing.paddingLg,
              child: ShimmerList(),
            );
          }
          if (state.status == CalendarEventDetailStatus.error) {
            return AppErrorWidget(
              message: state.errorMessage ?? 'Unable to load event details.',
            );
          }

          final e = state.event!;
          return _buildContent(theme, e);
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme, CalendarEventModel e) {
    final color = _colorForType(e.type, theme);
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return SingleChildScrollView(
      padding: AppSpacing.paddingXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(_iconForType(e.type), color: color, size: 28),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    AppSpacing.gapXs,
                    Chip(
                      label: Text(e.type.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: color)),
                      backgroundColor: color.withValues(alpha: 0.08),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapXxl,
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: dateFormat.format(e.startTime),
          ),
          AppSpacing.gapLg,
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: '${timeFormat.format(e.startTime)} - ${timeFormat.format(e.endTime)}',
          ),
          if (e.location != null) ...[
            AppSpacing.gapLg,
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: e.location!,
            ),
          ],
          if (e.description != null) ...[
            const Divider(height: 32),
            Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            AppSpacing.gapSm,
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
        AppSpacing.hGapMd,
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
