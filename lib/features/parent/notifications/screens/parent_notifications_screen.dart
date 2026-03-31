import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Grades',
    'Attendance',
    'Announcements',
    'Messages',
  ];

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      type: _NotificationType.gradeUpdate,
      title: 'Math Grade Posted',
      description: 'Omar received 92% on the Mid-Term Mathematics exam.',
      time: '10 min ago',
      group: 'Today',
      isRead: false,
    ),
    _NotificationItem(
      type: _NotificationType.attendanceAlert,
      title: 'Late Arrival Recorded',
      description:
          'Layla was marked late for the first period today at 8:12 AM.',
      time: '1 hr ago',
      group: 'Today',
      isRead: false,
    ),
    _NotificationItem(
      type: _NotificationType.announcement,
      title: 'School Event: Science Fair',
      description:
          'The annual Science Fair is scheduled for April 5. Volunteers welcome!',
      time: '3 hrs ago',
      group: 'Today',
      isRead: true,
    ),
    _NotificationItem(
      type: _NotificationType.message,
      title: 'Message from Mr. Ahmed',
      description:
          'Omar is doing great in class. Keep encouraging his homework routine.',
      time: 'Yesterday, 4:30 PM',
      group: 'Yesterday',
      isRead: true,
    ),
    _NotificationItem(
      type: _NotificationType.gradeUpdate,
      title: 'Science Quiz Results',
      description: 'Layla scored 88% on the Biology quiz. Great improvement!',
      time: 'Yesterday, 2:00 PM',
      group: 'Yesterday',
      isRead: true,
    ),
    _NotificationItem(
      type: _NotificationType.announcement,
      title: 'Holiday Schedule Update',
      description:
          'School will be closed from April 10-14 for the spring break.',
      time: 'Mar 20',
      group: 'Older',
      isRead: true,
    ),
    _NotificationItem(
      type: _NotificationType.attendanceAlert,
      title: 'Absent Without Notice',
      description: 'Omar was marked absent on March 19. Please confirm.',
      time: 'Mar 19',
      group: 'Older',
      isRead: true,
    ),
    _NotificationItem(
      type: _NotificationType.message,
      title: 'Message from Ms. Fatima',
      description:
          'Reminder: Science project materials are due by next Monday.',
      time: 'Mar 18',
      group: 'Older',
      isRead: true,
    ),
  ];

  List<_NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case 'Grades':
          return n.type == _NotificationType.gradeUpdate;
        case 'Attendance':
          return n.type == _NotificationType.attendanceAlert;
        case 'Announcements':
          return n.type == _NotificationType.announcement;
        case 'Messages':
          return n.type == _NotificationType.message;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<_NotificationItem>> get _groupedNotifications {
    final map = <String, List<_NotificationItem>>{};
    for (final n in _filteredNotifications) {
      map.putIfAbsent(n.group, () => []).add(n);
    }
    return map;
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dismissNotification(_NotificationItem item) {
    final index = _notifications.indexOf(item);
    setState(() => _notifications.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification dismissed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _notifications.insert(index, item));
          },
        ),
      ),
    );
  }

  IconData _iconForType(_NotificationType type) {
    switch (type) {
      case _NotificationType.gradeUpdate:
        return Icons.grade_outlined;
      case _NotificationType.attendanceAlert:
        return Icons.event_busy_outlined;
      case _NotificationType.announcement:
        return Icons.campaign_outlined;
      case _NotificationType.message:
        return Icons.chat_bubble_outline;
    }
  }

  Color _colorForType(_NotificationType type) {
    switch (type) {
      case _NotificationType.gradeUpdate:
        return AppColors.secondary;
      case _NotificationType.attendanceAlert:
        return const Color(0xFFF57C00);
      case _NotificationType.announcement:
        return AppColors.primary;
      case _NotificationType.message:
        return const Color(0xFF7C4DFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedNotifications;
    final groupOrder = ['Today', 'Yesterday', 'Older'];
    final activeGroups =
        groupOrder.where((g) => grouped.containsKey(g)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: activeGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final groupName = activeGroups[groupIndex];
                      final items = grouped[groupName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              groupName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          ...items.map(
                            (item) => _buildNotificationTile(item),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildNotificationTile(_NotificationItem item) {
    final color = _colorForType(item.type);
    final icon = _iconForType(item.type);

    return Dismissible(
      key: ValueKey('${item.title}_${item.time}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismissNotification(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _NotificationType { gradeUpdate, attendanceAlert, announcement, message }

class _NotificationItem {
  final _NotificationType type;
  final String title;
  final String description;
  final String time;
  final String group;
  bool isRead;

  _NotificationItem({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    required this.group,
    required this.isRead,
  });
}
