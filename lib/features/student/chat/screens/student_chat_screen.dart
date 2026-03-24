import 'package:flutter/material.dart';
import 'chat_conversation_screen.dart';

/// Chat with group chats and inbox tabs.
class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final List<_ChatItem> _groups = const [
    _ChatItem(
      id: 'g1',
      title: 'Grade 11-B Physics',
      preview: 'Lab notes uploaded for tomorrow.',
      time: '10:24',
      unread: 2,
    ),
    _ChatItem(
      id: 'g2',
      title: 'Math Practice Team',
      preview: 'Who solved question #8?',
      time: 'Yesterday',
      unread: 0,
    ),
  ];

  final List<_ChatItem> _inbox = const [
    _ChatItem(
      id: 'd1',
      title: 'Mrs. Hana (Teacher)',
      preview: 'Please submit your assignment by 5PM.',
      time: '09:12',
      unread: 1,
    ),
    _ChatItem(
      id: 'd2',
      title: 'Samuel T.',
      preview: 'Can we revise together later?',
      time: 'Mon',
      unread: 0,
    ),
  ];

  void _openConversation(_ChatItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversationId: item.id,
          title: item.title,
        ),
      ),
    );
  }

  void _showComposeOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('New Group Conversation'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Group creation flow opened.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_rounded),
              title: const Text('New Direct Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Contact picker opened.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
        body: TabBarView(
          children: [
            _ChatList(items: _groups, onTapItem: _openConversation),
            _ChatList(items: _inbox, onTapItem: _openConversation),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Start conversation',
          onPressed: _showComposeOptions,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final List<_ChatItem> items;
  final ValueChanged<_ChatItem> onTapItem;

  const _ChatList({required this.items, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(item.title.characters.first.toUpperCase()),
          ),
          title: Text(item.title),
          subtitle: Text(item.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              if (item.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.unread}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          onTap: () => onTapItem(item),
        );
      },
    );
  }
}

class _ChatItem {
  final String id;
  final String title;
  final String preview;
  final String time;
  final int unread;

  const _ChatItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.time,
    required this.unread,
  });
}
