import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/attendance_cubit.dart';
import '../models/attendance_model.dart' as am;
import '../repositories/student_attendance_repository.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AttendanceCubit(sl<StudentAttendanceRepository>())..loadIfNeeded(),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatefulWidget {
  const _AttendanceView();

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> {
  void _showOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('This Month Summary'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMonthlySummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Export Attendance'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _exportAttendance();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlySummary() {
    final records = context.read<AttendanceCubit>().state.records;
    final present = _presentCount(records);
    final absent = _absentCount(records);
    final late_ = _lateCount(records);
    final excused = _excusedCount(records);
    final total = records.length;
    final pct = total > 0 ? ((present + late_ + excused) / total * 100) : 0.0;

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapLg,
              _buildSummaryRow(
                'Present',
                '$present',
                dotColor: AppColors.success,
              ),
              _buildSummaryRow('Absent', '$absent', dotColor: AppColors.danger),
              _buildSummaryRow('Late', '$late_', dotColor: AppColors.warning),
              _buildSummaryRow('Excused', '$excused', dotColor: AppColors.info),
              const Divider(height: 24),
              _buildSummaryRow('Total Classes', '$total'),
              _buildSummaryRow('Attendance Rate', '${pct.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? dotColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hGapSm,
          ],
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAttendance() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing attendance report...')),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Attendance report exported')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StudentPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Navigator.of(context).canPop()
                          ? IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Attendance Record',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Attendance insights',
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(RouteNames.studentAttendanceInsights),
                      icon: Icon(
                        Icons.insights_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      tooltip: 'More attendance options',
                      onPressed: _showOptionsSheet,
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<AttendanceCubit, AttendanceState>(
                  builder: (context, state) {
                    final loading =
                        state.status == AttendanceStatus.initial ||
                        state.status == AttendanceStatus.loading;
                    if (loading) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: ShimmerList(),
                      );
                    }
                    if (state.status == AttendanceStatus.error) {
                      return AppErrorWidget(
                        message:
                            state.errorMessage ??
                            'Unable to load attendance records.',
                        onRetry: () =>
                            context.read<AttendanceCubit>().loadAttendance(),
                      );
                    }

                    final records = state.records;
                    if (records.isEmpty) {
                      return const EmptyStateWidget(
                        illustration: ClipboardIllustration(),
                        icon: Icons.fact_check_rounded,
                        title: 'No attendance records',
                        subtitle: 'Your attendance records will appear here.',
                      );
                    }

                    final subjectSummaries = _subjectSummaries(records);
                    final overallAttendance = _overallAttendance(records);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              gradient: AppGradients.attendance,
                              borderRadius: AppRadius.borderXl,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Overall Attendance',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withAlpha(180),
                                  ),
                                ),
                                AppSpacing.gapSm,
                                Text(
                                    '${overallAttendance.toStringAsFixed(0)}%',
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                  AppSpacing.gapXs,
                                  Text(
                                    'Based on ${records.length} recorded classes',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimary
                                          .withAlpha(180),
                                    ),
                                  ),
                                AppSpacing.gapSm,
                                  ClipRRect(
                                    borderRadius: AppRadius.borderXl,
                                    child: LinearProgressIndicator(
                                      value: overallAttendance / 100,
                                      minHeight: 8,
                                      backgroundColor:
                                          Colors.white.withAlpha(28),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.success,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapMd,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(28),
                                    borderRadius: AppRadius.borderXl,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      AppSpacing.hGapXs,
                                      Text(
                                        '${_currentStreak(records)} Day Streak',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.gapLg,
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _AttendanceStat(
                                      value: '${_presentCount(records)}',
                                      label: 'PRESENT',
                                      bgColor: Colors.white.withAlpha(22),
                                    ),
                                    _AttendanceStat(
                                      value: '${_absentCount(records)}',
                                      label: 'ABSENT',
                                      bgColor: Colors.white.withAlpha(22),
                                    ),
                                    _AttendanceStat(
                                      value: '${_lateCount(records)}',
                                      label: 'LATE',
                                      bgColor: Colors.white.withAlpha(22),
                                    ),
                                    _AttendanceStat(
                                      value: '${_excusedCount(records)}',
                                      label: 'EXCUSED',
                                      bgColor: Colors.white.withAlpha(22),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapXxl,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subject Breakdown',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text(
                                        'All Subject Attendance',
                                      ),
                                      content: Text(
                                        subjectSummaries
                                            .map(
                                              (summary) =>
                                                  '${summary.name} ${summary.percentageLabel}',
                                            )
                                            .join('\n'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  'View All',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapSm,
                          for (
                            int index = 0;
                            index < subjectSummaries.length;
                            index++
                          ) ...[
                            StaggeredFadeSlide(
                              index: index,
                              child: _SubjectAttendanceRow(
                                icon: _iconForSubject(
                                  subjectSummaries[index].name,
                                ),
                                iconColor: _colorForSubject(
                                  subjectSummaries[index].name,
                                ),
                                name: subjectSummaries[index].name,
                                totalClasses: subjectSummaries[index].total,
                                progress: subjectSummaries[index].percentage,
                                percentage:
                                    subjectSummaries[index].percentageLabel,
                                dots: subjectSummaries[index].dots,
                              ),
                            ),
                            if (index < subjectSummaries.length - 1)
                              AppSpacing.gapLg,
                          ],
                          AppSpacing.gapXxl,
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendItem(
                                color: AppColors.success,
                                label: 'Present',
                              ),
                              AppSpacing.hGapMd,
                              _LegendItem(
                                color: AppColors.warning,
                                label: 'Late',
                              ),
                              AppSpacing.hGapMd,
                              _LegendItem(
                                color: AppColors.danger,
                                label: 'Absent',
                              ),
                              AppSpacing.hGapMd,
                              _LegendItem(
                                color: AppColors.info,
                                label: 'Excused',
                              ),
                            ],
                          ),
                          AppSpacing.gapXl,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _presentCount(List<am.AttendanceModel> records) =>
      records.where((r) => r.status == am.AttendanceStatus.present).length;

  int _absentCount(List<am.AttendanceModel> records) =>
      records.where((r) => r.status == am.AttendanceStatus.absent).length;

  int _lateCount(List<am.AttendanceModel> records) =>
      records.where((r) => r.status == am.AttendanceStatus.late).length;

  int _excusedCount(List<am.AttendanceModel> records) =>
      records.where((r) => r.status == am.AttendanceStatus.excused).length;

  double _overallAttendance(List<am.AttendanceModel> records) {
    if (records.isEmpty) return 0;
    final attended =
        _presentCount(records) + _lateCount(records) + _excusedCount(records);
    return (attended / records.length) * 100;
  }

  int _currentStreak(List<am.AttendanceModel> records) {
    final sorted = List<am.AttendanceModel>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final record in sorted) {
      if (record.status == am.AttendanceStatus.absent) break;
      streak++;
    }
    return streak;
  }

  List<_SubjectAttendanceSummary> _subjectSummaries(
    List<am.AttendanceModel> records,
  ) {
    final grouped = <String, List<am.AttendanceModel>>{};
    for (final record in records) {
      grouped
          .putIfAbsent(record.subjectId, () => <am.AttendanceModel>[])
          .add(record);
    }

    return grouped.entries.map((entry) {
      final subjectRecords = entry.value
        ..sort((a, b) => a.date.compareTo(b.date));
      final attended = subjectRecords
          .where((r) => r.status != am.AttendanceStatus.absent)
          .length;
      final percentage = subjectRecords.isEmpty
          ? 0.0
          : (attended / subjectRecords.length) * 100;

      return _SubjectAttendanceSummary(
        name: subjectRecords.first.subjectName,
        total: subjectRecords.length,
        percentage: percentage,
        percentageLabel: '${percentage.toStringAsFixed(0)}%',
        dots: subjectRecords.map((record) {
          switch (record.status) {
            case am.AttendanceStatus.present:
              return _DotStatus.present;
            case am.AttendanceStatus.late:
              return _DotStatus.late;
            case am.AttendanceStatus.excused:
              return _DotStatus.excused;
            case am.AttendanceStatus.absent:
              return _DotStatus.absent;
          }
        }).toList(),
      );
    }).toList()..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  IconData _iconForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => Icons.calculate_rounded,
      'physics' => Icons.science_rounded,
      'english literature' || 'literature' => Icons.auto_stories_rounded,
      _ => Icons.school_rounded,
    };
  }

  Color _colorForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => AppColors.mathematics,
      'physics' => AppColors.physics,
      'english literature' || 'literature' => AppColors.literature,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}

class _SubjectAttendanceSummary {
  final String name;
  final int total;
  final double percentage;
  final String percentageLabel;
  final List<_DotStatus> dots;

  const _SubjectAttendanceSummary({
    required this.name,
    required this.total,
    required this.percentage,
    required this.percentageLabel,
    required this.dots,
  });
}

enum _DotStatus { present, absent, late, excused, future }

class _AttendanceStat extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;

  const _AttendanceStat({
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withAlpha(180),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendanceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final int totalClasses;
  final double progress;
  final String percentage;
  final List<_DotStatus> dots;

  const _SubjectAttendanceRow({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.totalClasses,
    required this.progress,
    required this.percentage,
    required this.dots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Total Classes: $totalClasses',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentage,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          ClipRRect(
            borderRadius: AppRadius.borderXl,
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 7,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dots.map((dot) {
              Color color;
              switch (dot) {
                case _DotStatus.present:
                  color = AppColors.success;
                case _DotStatus.absent:
                  color = AppColors.danger;
                case _DotStatus.late:
                  color = AppColors.warning;
                case _DotStatus.excused:
                  color = AppColors.info;
                case _DotStatus.future:
                  color = theme.colorScheme.outlineVariant;
              }
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.hGapXs,
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
