import 'package:flutter/material.dart';
import '../widgets/notification_tile.dart';

/// Personalized notifications (academic, administrative, marketing).
/// Supports mark as read/unread.
class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  int _filterIndex = 0;
  final List<_NotificationItem> _items = [
    _NotificationItem(
      title: 'Math Quiz Reminder',
      body: 'Your Algebra quiz starts tomorrow at 9:00 AM.',
      time: '10m ago',
      isRead: false,
    ),
    _NotificationItem(
      title: 'Attendance Alert',
      body: 'You have 2 absences recorded this week.',
      time: '1h ago',
      isRead: false,
    ),
    _NotificationItem(
      title: 'New Announcement',
      body: 'School science fair registration is now open.',
      time: 'Yesterday',
      isRead: true,
    ),
  ];

  List<_NotificationItem> get _visibleItems {
    if (_filterIndex == 1) {
      return _items.where((item) => !item.isRead).toList();
    }
    return _items;
  }

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterIndex == 0,
                  onSelected: (_) => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Unread'),
                  selected: _filterIndex == 1,
                  onSelected: (_) => setState(() => _filterIndex = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleItems.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications in this view.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return NotificationTile(
                        isRead: item.isRead,
                        title: item.title,
                        body: item.body,
                        time: item.time,
                        onTap: () {
                          setState(() => item.isRead = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(item.title)),
                          );
                        },
                        onToggleRead: () {
                          setState(() => item.isRead = !item.isRead);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String body;
  final String time;
  bool isRead;

  _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
