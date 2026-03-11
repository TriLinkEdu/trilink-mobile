import 'package:flutter/material.dart';

/// Chat with group chats and inbox tabs.
class StudentChatScreen extends StatelessWidget {
  const StudentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Groups'),
              Tab(text: 'Inbox'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('TODO: Group chats')),
            Center(child: Text('TODO: Inbox / Direct messages')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Start new conversation
          },
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
