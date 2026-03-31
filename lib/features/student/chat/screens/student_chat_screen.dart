import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import '../repositories/mock_student_chat_repository.dart';
import 'chat_conversation_screen.dart';

class StudentChatScreen extends StatefulWidget {
  final StudentChatRepository? repository;

  const StudentChatScreen({super.key, this.repository});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  late final StudentChatRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<ChatConversationModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentChatRepository();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final conversations = await _repository.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load conversations.';
        _isLoading = false;
      });
    }
  }

  List<ChatConversationModel> get _groups =>
      _conversations.where((c) => c.isGroup).toList();

  List<ChatConversationModel> get _inbox =>
      _conversations.where((c) => !c.isGroup).toList();

  void _openConversation(ChatConversationModel conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversationId: conversation.id,
          title: conversation.title,
          repository: _repository,
        ),
      ),
    ).then((_) => _loadConversations());
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
                final conversation = await _repository.createConversation(
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
              final conversation = await _repository.createConversation(
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadConversations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
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
