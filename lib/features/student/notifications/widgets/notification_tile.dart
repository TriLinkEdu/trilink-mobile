import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final bool isRead;

  const NotificationTile({super.key, this.isRead = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isRead ? Icons.notifications_none : Icons.notifications_active,
        color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Notification Title'),
      subtitle: const Text('Notification body...'),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      // TODO: Implement mark as read/unread
    );
  }
}
