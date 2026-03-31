import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String body;
  final String? timeLabel;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.body,
    this.timeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.campaign),
        title: Text(title),
        subtitle: Text(
          timeLabel == null ? body : '$body\n$timeLabel',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
