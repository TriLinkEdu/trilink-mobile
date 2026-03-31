import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/chat_cubit.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_conversation_screen.dart';

class StudentChatScreen extends StatelessWidget {
  const StudentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChatCubit(sl<StudentChatRepository>())..loadConversations(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  void _openConversation(ChatConversationModel conversation) {
    final cubit = context.read<ChatCubit>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversationId: conversation.id,
          title: conversation.title,
        ),
      ),
    )
        .then((_) => cubit.loadConversations());
  }

  void _showComposeOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('New Group Conversation'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showNewGroupDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_rounded),
              title: const Text('New Direct Message'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showNewDmDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewGroupDialog() {
    final nameController = TextEditingController();
    final mockContacts = <String, String>{
      'student2': 'Alice Chen',
      'student3': 'Carlos Rivera',
      'student5': 'Bob Martinez',
      'student6': 'Fatima Al-Rashid',
      'student8': 'Emily Davis',
    };
    final selected = <String>{};

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'Enter group name',
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select participants:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                ...mockContacts.entries.map((entry) {
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                    value: selected.contains(entry.key),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) {
                          selected.add(entry.key);
                        } else {
                          selected.remove(entry.key);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selected.isEmpty) return;
                Navigator.pop(dialogContext);
                final conversation = await sl<StudentChatRepository>()
                    .createConversation(
                  title: name,
                  participantIds: ['student1', ...selected],
                  isGroup: true,
                );
                if (!mounted) return;
                _openConversation(conversation);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewDmDialog() {
    final mockContacts = <String, String>{
      'student2': 'Alice Chen',
      'student3': 'Carlos Rivera',
      'student5': 'Bob Martinez',
      'student6': 'Fatima Al-Rashid',
      'student7': 'Sarah Johnson',
      'student8': 'Emily Davis',
      'prof1': 'Prof. Williams',
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Start Direct Message'),
        children: mockContacts.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final conversation = await sl<StudentChatRepository>()
                  .createConversation(
                title: entry.value,
                participantIds: ['student1', entry.key],
                isGroup: false,
              );
              if (!mounted) return;
              _openConversation(conversation);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(entry.value.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Text(entry.value),
              ],
            ),
          );
        }).toList(),
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
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final loading = state.status == ChatStatus.initial ||
                state.status == ChatStatus.loading;
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ChatStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Unable to load conversations.',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ChatCubit>().loadConversations(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final conversations = state.conversations;
            final groups =
                conversations.where((c) => c.isGroup).toList();
            final inbox =
                conversations.where((c) => !c.isGroup).toList();

            return TabBarView(
              children: [
                _ChatList(items: groups, onTapItem: _openConversation),
                _ChatList(items: inbox, onTapItem: _openConversation),
              ],
            );
          },
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
  final List<ChatConversationModel> items;
  final ValueChanged<ChatConversationModel> onTapItem;

  const _ChatList({required this.items, required this.onTapItem});

  String _previewText(ChatConversationModel conversation) {
    final msg = conversation.lastMessage;
    if (msg == null) return 'No messages yet';
    return msg.content;
  }

  String _timeLabel(ChatConversationModel conversation) {
    final msg = conversation.lastMessage;
    if (msg == null) return '';
    final diff = DateTime.now().difference(msg.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
          subtitle: Text(
            _previewText(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel(item),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              if (item.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.unreadCount}',
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 11),
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
