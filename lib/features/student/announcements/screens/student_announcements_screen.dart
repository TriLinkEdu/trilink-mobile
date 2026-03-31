import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/announcements_cubit.dart';
import '../models/announcement_model.dart';
import '../repositories/student_announcements_repository.dart';

class StudentAnnouncementsScreen extends StatelessWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AnnouncementsCubit(sl<StudentAnnouncementsRepository>())
            ..loadAnnouncements(),
      child: const _StudentAnnouncementsView(),
    );
  }
}

class _StudentAnnouncementsView extends StatefulWidget {
  const _StudentAnnouncementsView();

  @override
  State<_StudentAnnouncementsView> createState() =>
      _StudentAnnouncementsViewState();
}

class _StudentAnnouncementsViewState extends State<_StudentAnnouncementsView> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Admin', 'Teacher', 'Calendar'];

  List<AnnouncementModel> _visibleAnnouncements(List<AnnouncementModel> announcements) {
    if (_selectedFilter == 0) return announcements;
    final selectedCategory = _filters[_selectedFilter].toLowerCase();
    if (selectedCategory == 'calendar') {
      return announcements
          .where((announcement) => announcement.category == 'calendar')
          .toList();
    }
    return announcements
        .where((announcement) =>
            announcement.authorRole.toLowerCase() == selectedCategory)
        .toList();
  }

  int _recentUnreadCount(List<AnnouncementModel> announcements) {
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    return announcements
        .where((a) => a.createdAt.isAfter(oneDayAgo))
        .length;
  }

  void _openAnnouncementDetail(AnnouncementModel announcement) {
    Navigator.of(context).pushNamed(
      RouteNames.studentAnnouncementDetail,
      arguments: {'announcementId': announcement.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    label: 'Back',
                    button: true,
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Announcements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
                    buildWhen: (previous, current) =>
                        previous.announcements != current.announcements,
                    builder: (context, state) {
                      final count = _recentUnreadCount(state.announcements);
                      return Stack(
                        children: [
                          IconButton(
                            tooltip: 'Announcement notifications',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(count > 0
                                      ? '$count announcement${count == 1 ? '' : 's'} in the last 24 hours.'
                                      : 'No recent announcements.'),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Pressable(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: Semantics(
                        selected: isSelected,
                        button: true,
                        label: 'Filter ${_filters[index]}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: AppRadius.borderXl,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            AppSpacing.gapLg,

            Expanded(
              child: BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
                builder: (context, state) {
                  if (state.status == AnnouncementsStatus.loading ||
                      state.status == AnnouncementsStatus.initial) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: ShimmerList(),
                    );
                  }
                  if (state.status == AnnouncementsStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.errorMessage ?? '',
                              style: const TextStyle(color: AppColors.danger)),
                          AppSpacing.gapSm,
                          ElevatedButton(
                            onPressed: () => context
                                .read<AnnouncementsCubit>()
                                .loadAnnouncements(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final announcements = state.announcements;
                  final visible = _visibleAnnouncements(announcements);
                  return ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (visible.isEmpty) ...[
                        AppSpacing.gapHuge,
                        Center(
                          child: Text(
                            'No announcements in this category yet.',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                        AppSpacing.gapHuge,
                      ] else ...[
                        for (final section
                            in {'TODAY', 'YESTERDAY'}) ...[
                          if (visible.any(
                            (announcement) =>
                                _sectionFor(announcement) == section,
                          )) ...[
                            _SectionHeader(title: section),
                            AppSpacing.gapSm,
                            for (final announcement
                                in visible.where(
                              (item) =>
                                  _sectionFor(item) == section,
                            )) ...[
                              Pressable(
                                onTap: () => _openAnnouncementDetail(
                                    announcement),
                                child: _AnnouncementItem(
                                  icon: _iconFor(announcement),
                                  iconColor:
                                      _iconColorFor(announcement),
                                  iconBgColor:
                                      _iconBgFor(announcement),
                                  title: announcement.title,
                                  subtitle: announcement.authorName,
                                  time: _timeLabel(
                                      announcement.createdAt),
                                  body: announcement.body,
                                ),
                              ),
                              AppSpacing.gapSm,
                            ],
                            AppSpacing.gapSm,
                          ],
                        ],
                      ],
                      AppSpacing.gapXxl,
                      Center(
                        child: Text(
                          'You\'re all caught up',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      AppSpacing.gapXl,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionFor(AnnouncementModel model) {
    final daysAgo = DateTime.now().difference(model.createdAt).inDays;
    return daysAgo <= 0 ? 'TODAY' : 'YESTERDAY';
  }

  String _timeLabel(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }

  IconData _iconFor(AnnouncementModel model) {
    if (model.category == 'calendar') return Icons.calendar_today_rounded;
    if (model.authorRole.toLowerCase() == 'teacher') {
      return Icons.school_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  Color _iconColorFor(AnnouncementModel model) {
    if (model.category == 'calendar') {
      return Theme.of(context).colorScheme.primary;
    }
    if (model.authorRole.toLowerCase() == 'teacher') return AppColors.warning;
    return AppColors.danger;
  }

  Color _iconBgFor(AnnouncementModel model) {
    if (model.category == 'calendar') return const Color(0xFFDBEAFE);
    if (model.authorRole.toLowerCase() == 'teacher') {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFFEE2E2);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String time;
  final String body;

  const _AnnouncementItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapXxs,
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                AppSpacing.gapSm,
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
