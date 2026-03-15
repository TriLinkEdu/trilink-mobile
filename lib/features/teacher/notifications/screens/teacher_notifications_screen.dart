import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Student Activity', 'System Alerts'];

  final List<_NotificationGroup> _groups = [
    _NotificationGroup(
      label: 'TODAY',
      items: [
        _NotificationItem(
          icon: Icons.assignment_turned_in,
          iconBgColor: AppColors.primary,
          title: 'Sara Mekonnen',
          subtitle: 'Submitted Physics Quiz: Module 3',
          time: '2m ago',
          isRead: false,
          type: 'student',
        ),
        _NotificationItem(
          icon: Icons.warning_amber_rounded,
          iconBgColor: AppColors.error,
          title: 'System Alert',
          subtitle:
              'Grading system maintenance scheduled for tonight at 11:00 PM EST.',
          time: '45m ago',
          isRead: false,
          type: 'system',
        ),
      ],
    ),
    _NotificationGroup(
      label: 'YESTERDAY',
      items: [
        _NotificationItem(
          icon: Icons.campaign,
          iconBgColor: Colors.purple,
          title: 'Admin Announcement',
          subtitle:
              'New holiday schedule guidelines have been posted for the upcoming semester.',
          time: '1d ago',
          isRead: true,
          type: 'system',
        ),
        _NotificationItem(
          icon: Icons.person,
          iconBgColor: Colors.orange,
          title: 'John Doe',
          subtitle: 'Requested an extension on History Essay.',
          time: '1d ago',
          isRead: true,
          type: 'student',
          highlightText: 'History Essay',
        ),
      ],
    ),
    _NotificationGroup(
      label: 'OLDER',
      items: [
        _NotificationItem(
          icon: Icons.grading,
          iconBgColor: AppColors.secondary,
          title: 'Grades Published',
          subtitle:
              'Mid-term results have been released to students.',
          time: '3d ago',
          isRead: true,
          type: 'system',
        ),
      ],
    ),
  ];

  List<_NotificationGroup> get _filteredGroups {
    if (_selectedFilter == 0) return _groups;
    final filterType = _selectedFilter == 1 ? 'student' : 'system';
    return _groups
        .map((g) => _NotificationGroup(
              label: g.label,
              items: g.items.where((i) => i.type == filterType).toList(),
            ))
        .where((g) => g.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                for (final g in _groups) {
                  for (final i in g.items) {
                    i.isRead = true;
                  }
                }
              });
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
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
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textPrimary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textPrimary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final groups = _filteredGroups;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                group.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Divider(height: 1),
            ...group.items.map((item) => _NotificationTile(item: item)),
            if (groupIndex < groups.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                  height: 1,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationGroup {
  final String label;
  final List<_NotificationItem> items;
  _NotificationGroup({required this.label, required this.items});
}

class _NotificationItem {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String time;
  bool isRead;
  final String type;
  final String? highlightText;

  _NotificationItem({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    required this.type,
    this.highlightText,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.iconBgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconBgColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              item.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildSubtitle(),
              ],
            ),
          ),
          if (!item.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    if (item.highlightText != null) {
      final parts = item.subtitle.split(item.highlightText!);
      return RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          children: [
            TextSpan(text: parts.first),
            TextSpan(
              text: item.highlightText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts.last),
          ],
        ),
      );
    }
    return Text(
      item.subtitle,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
        height: 1.4,
      ),
    );
  }
}
