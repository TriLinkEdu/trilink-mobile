import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

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

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final unreadOnly = _selectedFilter == 1; // index 1 = "Unread"
      final data = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data.map((n) => n as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService().markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['readAt'] = DateTime.now().toIso8601String();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark all read: $e')));
    }
  }

  Future<void> _markRead(String id, int index) async {
    try {
      await ApiService().markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        _notifications[index]['readAt'] = DateTime.now().toIso8601String();
      });
    } catch (_) {}
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  String _groupLabel(String? dateStr) {
    if (dateStr == null) return 'OLDER';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final notifDate = DateTime(date.year, date.month, date.day);

      if (notifDate == today) return 'TODAY';
      if (notifDate == yesterday) return 'YESTERDAY';
      return 'OLDER';
    } catch (_) {
      return 'OLDER';
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_turned_in;
      case 'alert':
      case 'system':
        return Icons.warning_amber_rounded;
      case 'announcement':
        return Icons.campaign;
      case 'grade':
        return Icons.grading;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'assignment':
        return AppColors.primary;
      case 'alert':
      case 'system':
        return AppColors.error;
      case 'announcement':
        return Colors.purple;
      case 'grade':
        return AppColors.secondary;
      default:
        return Colors.orange;
    }
  }

  List<_NotificationGroup> get _groupedNotifications {
    final filtered = _selectedFilter == 0
        ? _notifications
        : _notifications.where((n) {
            final type = n['type'] as String? ?? '';
            if (_selectedFilter == 1) {
              return type == 'assignment' || type == 'student';
            }
            return type == 'system' ||
                type == 'alert' ||
                type == 'announcement' ||
                type == 'grade';
          }).toList();

    final Map<String, List<MapEntry<int, Map<String, dynamic>>>> grouped = {};
    for (int i = 0; i < filtered.length; i++) {
      final n = filtered[i];
      final originalIndex = _notifications.indexOf(n);
      final label = _groupLabel(n['createdAt'] as String?);
      grouped.putIfAbsent(label, () => []).add(MapEntry(originalIndex, n));
    }

    const order = ['TODAY', 'YESTERDAY', 'OLDER'];
    return order
        .where((label) => grouped.containsKey(label))
        .map(
          (label) => _NotificationGroup(label: label, items: grouped[label]!),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    return _buildNotificationsList();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _markAllRead,
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
                  color: isSelected ? AppColors.textPrimary : Colors.white,
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
    final groups = _groupedNotifications;
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No notifications',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        ),
      );
    }
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
            ...group.items.map((entry) {
              final n = entry.value;
              final originalIndex = entry.key;
              final id = n['id'] as String? ?? '';
              final isRead = n['readAt'] != null;
              final type = n['type'] as String?;

              return GestureDetector(
                onTap: () {
                  if (!isRead && id.isNotEmpty) {
                    _markRead(id, originalIndex);
                  }
                },
                child: _NotificationTile(
                  icon: _iconForType(type),
                  iconBgColor: _colorForType(type),
                  title: n['title'] as String? ?? '',
                  subtitle: n['body'] as String? ?? '',
                  time: _timeAgo(n['createdAt'] as String?),
                  isRead: isRead,
                ),
              );
            }),
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
  final List<MapEntry<int, Map<String, dynamic>>> items;
  _NotificationGroup({required this.label, required this.items});
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  const _NotificationTile({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });

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
              color: iconBgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBgColor, size: 20),
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
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead) ...[
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
}
