import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.campaign),
        title: Text('Announcement Title'),
        subtitle: Text('Announcement body preview...'),
        // TODO: Complete with actual data
      ),
    );
  }
}
