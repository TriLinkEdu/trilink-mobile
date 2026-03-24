import 'package:flutter/material.dart';

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
    return ListTile(
      onTap: onTap,
      leading: Icon(
        isRead ? Icons.notifications_none : Icons.notifications_active,
        color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: onToggleRead,
        icon: Icon(
          isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
          color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
        ),
        tooltip: isRead ? 'Mark as unread' : 'Mark as read',
      ),
    );
  }
}
