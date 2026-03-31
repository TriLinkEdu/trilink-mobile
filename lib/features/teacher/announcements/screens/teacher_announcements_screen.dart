import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/create_announcement_screen.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Sent', 'Scheduled', 'Draft'];

  final List<_AnnouncementItem> _announcements = [
    _AnnouncementItem(
      title: 'Mid-Term Exam Schedule Released',
      preview:
          'The mid-term examination schedule for all classes has been finalized. Please review the dates and prepare accordingly.',
      audiences: ['10A', '10B', '11A'],
      dateTime: 'Mar 20, 2026 • 9:00 AM',
      status: _AnnouncementStatus.sent,
      attachments: 1,
    ),
    _AnnouncementItem(
      title: 'Science Fair Project Deadline Extended',
      preview:
          'Due to multiple requests, the deadline for submitting science fair projects has been extended by one week.',
      audiences: ['11A', '11B'],
      dateTime: 'Mar 22, 2026 • 2:30 PM',
      status: _AnnouncementStatus.sent,
      attachments: 0,
    ),
    _AnnouncementItem(
      title: 'Parent-Teacher Conference Reminder',
      preview:
          'Reminder: Parent-Teacher conferences are scheduled for next Friday. Please ensure all grade reports are updated.',
      audiences: ['All Classes'],
      dateTime: 'Mar 25, 2026 • 8:00 AM',
      status: _AnnouncementStatus.scheduled,
      attachments: 2,
    ),
    _AnnouncementItem(
      title: 'Lab Safety Training Required',
      preview:
          'All students enrolled in Chemistry and Biology must complete the online lab safety module before attending next lab session.',
      audiences: ['10B', '11A'],
      dateTime: 'Mar 26, 2026 • 10:00 AM',
      status: _AnnouncementStatus.scheduled,
      attachments: 1,
    ),
    _AnnouncementItem(
      title: 'End-of-Year Trip Planning',
      preview:
          'We are planning the annual end-of-year educational trip. Details about destinations and costs will be shared soon.',
      audiences: ['12A'],
      dateTime: 'Edited Mar 18, 2026',
      status: _AnnouncementStatus.draft,
      attachments: 0,
    ),
  ];

  List<_AnnouncementItem> get _filteredAnnouncements {
    if (_selectedFilter == 'All') return _announcements;
    return _announcements.where((a) {
      switch (_selectedFilter) {
        case 'Sent':
          return a.status == _AnnouncementStatus.sent;
        case 'Scheduled':
          return a.status == _AnnouncementStatus.scheduled;
        case 'Draft':
          return a.status == _AnnouncementStatus.draft;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredAnnouncements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No $_selectedFilter announcements',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredAnnouncements.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _AnnouncementCard(
                        announcement: _filteredAnnouncements[index],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateAnnouncementScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _AnnouncementItem announcement;

  const _AnnouncementCard({required this.announcement});

  Color get _statusColor {
    switch (announcement.status) {
      case _AnnouncementStatus.sent:
        return AppColors.secondary;
      case _AnnouncementStatus.scheduled:
        return AppColors.primary;
      case _AnnouncementStatus.draft:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (announcement.status) {
      case _AnnouncementStatus.sent:
        return 'Sent';
      case _AnnouncementStatus.scheduled:
        return 'Scheduled';
      case _AnnouncementStatus.draft:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: announcement.audiences.map((audience) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  audience,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                announcement.dateTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (announcement.attachments > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${announcement.attachments} file${announcement.attachments > 1 ? 's' : ''}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _AnnouncementStatus { sent, scheduled, draft }

class _AnnouncementItem {
  final String title;
  final String preview;
  final List<String> audiences;
  final String dateTime;
  final _AnnouncementStatus status;
  final int attachments;

  _AnnouncementItem({
    required this.title,
    required this.preview,
    required this.audiences,
    required this.dateTime,
    required this.status,
    required this.attachments,
  });
}
