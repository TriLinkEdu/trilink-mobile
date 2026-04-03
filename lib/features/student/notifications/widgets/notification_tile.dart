import 'package:flutter/material.dart';

import 'package:trilink_mobile/core/widgets/pressable.dart';

class NotificationTile extends StatelessWidget {
  final bool isRead;
  final String title;
  final String body;
  final String time;
  final VoidCallback? onTap;
  final VoidCallback? onToggleRead;

  const NotificationTile({
    super.key,
    this.isRead = false,
    required this.title,
    required this.body,
    required this.time,
    this.onTap,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      enableHaptic: false,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isRead ? Icons.notifications_none : Icons.notifications_active,
          color: isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(body),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onToggleRead,
          icon: Icon(
            isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
            color: isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
          ),
          tooltip: isRead ? 'Mark as unread' : 'Mark as read',
        ),
      ),
    );
  }
}
