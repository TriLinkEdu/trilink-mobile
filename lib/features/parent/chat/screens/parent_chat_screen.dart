import 'package:flutter/material.dart';

/// Communicate with teachers and admins.
/// Option to view student-teacher conversations (chat viewer).
class ParentChatScreen extends StatelessWidget {
  const ParentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Chats'),
              Tab(text: 'Student Chats'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(
              child: Text('TODO: Parent direct messages with teachers/admins'),
            ),
            Center(child: Text('TODO: View student-teacher conversations')),
          ],
        ),
      ),
    );
  }
}
