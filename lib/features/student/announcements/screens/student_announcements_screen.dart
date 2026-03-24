import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/announcement_model.dart';
import '../repositories/mock_student_announcements_repository.dart';
import '../repositories/student_announcements_repository.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Admin', 'Teacher', 'Calendar'];
  final StudentAnnouncementsRepository _repository =
      MockStudentAnnouncementsRepository();
  bool _isLoading = true;
  String? _error;
  List<AnnouncementModel> _announcements = const [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcements = await _repository.fetchAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load announcements right now.';
        _isLoading = false;
      });
    }
  }

  List<AnnouncementModel> get _visibleAnnouncements {
    if (_selectedFilter == 0) return _announcements;
    final selectedCategory = _filters[_selectedFilter].toLowerCase();
    if (selectedCategory == 'calendar') {
      return _announcements
          .where((announcement) => announcement.category == 'calendar')
          .toList();
    }
    return _announcements
        .where((announcement) =>
            announcement.authorRole.toLowerCase() == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Announcements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No unread announcement notifications.'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Announcements list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _loadAnnouncements,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_visibleAnnouncements.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Text(
                        'No announcements in this category yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ] else ...[
                    for (final section in {'TODAY', 'YESTERDAY'}) ...[
                      if (_visibleAnnouncements.any(
                        (announcement) => _sectionFor(announcement) == section,
                      )) ...[
                        _SectionHeader(title: section),
                        const SizedBox(height: 10),
                        for (final announcement in _visibleAnnouncements.where(
                          (item) => _sectionFor(item) == section,
                        )) ...[
                          _AnnouncementItem(
                            icon: _iconFor(announcement),
                            iconColor: _iconColorFor(announcement),
                            iconBgColor: _iconBgFor(announcement),
                            title: announcement.title,
                            subtitle: announcement.authorName,
                            time: _timeLabel(announcement.createdAt),
                            body: announcement.body,
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'You\'re all caught up',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
    if (model.authorRole.toLowerCase() == 'teacher') return Icons.school_rounded;
    return Icons.warning_amber_rounded;
  }

  Color _iconColorFor(AnnouncementModel model) {
    if (model.category == 'calendar') return AppColors.primary;
    if (model.authorRole.toLowerCase() == 'teacher') return Colors.amber;
    return Colors.red;
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
