import 'package:flutter/material.dart';

/// Individual chat conversation screen.
class ChatConversationScreen extends StatelessWidget {
  final String conversationId;
  final String title;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Column(
        children: [
          Expanded(child: Center(child: Text('TODO: Message list'))),
          // TODO: Message input bar
        ],
      ),
    );
  }
}
