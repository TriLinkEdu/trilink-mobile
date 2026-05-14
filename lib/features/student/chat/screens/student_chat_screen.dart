import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/chat_cubit.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import 'connections_screen.dart';
import 'blocked_users_screen.dart';
import '../widgets/connection_request_dialog.dart';

class StudentChatScreen extends StatelessWidget {
  const StudentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(sl<StudentChatRepository>())..loadIfNeeded(),
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
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final user = await sl<StorageService>().getUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = (user?['id'] ?? '').toString();
    });
  }

  void _openConversation(ChatConversationModel conversation) {
    final cubit = context.read<ChatCubit>();
    Navigator.of(context)
        .pushNamed(
          RouteNames.studentChatConversation,
          arguments: {
            'conversationId': conversation.id,
            'title': conversation.title,
            'isGroup': conversation.isGroup,
            'avatarPath': conversation.avatarPath,
          },
        )
        .then((_) => cubit.loadConversations());
  }

  void _showComposeOptions() {
    // Students can only create DMs, not groups
    _showNewDmDialog();
  }

  void _showNewGroupDialog() async {
    final nameController = TextEditingController();
    final selected = <String>{};
    
    // Fetch real contacts from API
    List<ChatContactModel> contacts = [];
    try {
      contacts = await sl<StudentChatRepository>().searchUsers('');
    } catch (e) {
      // Fallback to empty list if API fails
      contacts = [];
    }

    if (!mounted) return;

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
                AppSpacing.gapLg,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select participants:',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (contacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No contacts available',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  )
                else
                  ...contacts.map((contact) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        contact.displayName,
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                      subtitle: contact.role == 'teacher' && contact.subject != null
                          ? Text(
                              contact.subject!,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            )
                          : null,
                      value: selected.contains(contact.id),
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            selected.add(contact.id);
                          } else {
                            selected.remove(contact.id);
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
                final conversation = await context
                    .read<ChatCubit>()
                    .createConversation(
                      title: name,
                      participantIds: [
                        if (_currentUserId.isNotEmpty) _currentUserId,
                        ...selected,
                      ],
                      isGroup: true,
                    );
                if (!mounted || conversation == null) return;
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        List<ChatContactModel> contacts = [];
        bool loading = false;
        String? error;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> search(String q) async {
              if (q.trim().length < 2) {
                setDialogState(() { contacts = []; loading = false; error = null; });
                return;
              }
              setDialogState(() { loading = true; error = null; });
              try {
                final results = await sl<StudentChatRepository>().searchUsers(q.trim());
                setDialogState(() { contacts = results; loading = false; });
              } catch (_) {
                setDialogState(() { loading = false; error = 'Search failed. Please try again.'; });
              }
            }

            final teachers = contacts.where((c) => c.role == 'teacher').toList();
            final students = contacts.where((c) => c.role == 'student').toList();
            final hasResults = teachers.isNotEmpty || students.isNotEmpty;

            return AlertDialog(
              title: const Text('New Message'),
              contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search by name…',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: search,
                      ),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            if (!hasResults)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    contacts.isEmpty ? 'Type at least 2 characters to search' : 'No results',
                                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            if (teachers.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Text('TEACHERS', style: Theme.of(ctx).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary)),
                              ),
                              ...teachers.map((contact) => ListTile(
                                leading: CircleAvatar(child: Text(contact.firstName[0])),
                                title: Text(contact.displayName),
                                subtitle: contact.subject != null ? Text(contact.subject!) : null,
                                onTap: () async {
                                  Navigator.pop(dialogContext);
                                  await _initiateDirectMessage(contact);
                                },
                              )),
                            ],
                            if (students.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Text('CLASSMATES', style: Theme.of(ctx).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary)),
                              ),
                              ...students.map((contact) => ListTile(
                                leading: CircleAvatar(child: Text(contact.firstName[0])),
                                title: Text(contact.fullName),
                                trailing: const Icon(Icons.person_add_outlined, size: 20),
                                onTap: () async {
                                  Navigator.pop(dialogContext);
                                  if (contact.id == _currentUserId) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You cannot connect with yourself.')),
                                    );
                                    return;
                                  }
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => ConnectionRequestDialog(
                                      contact: contact,
                                      repository: sl<StudentChatRepository>(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connection request sent to ${contact.fullName}')),
                                    );
                                  }
                                },
                              )),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _initiateDirectMessage(ChatContactModel contact) async {
    try {
      if (contact.id == _currentUserId && _currentUserId.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You cannot message yourself.')),
        );
        return;
      }
      final conversation = await context.read<ChatCubit>().createConversation(
        title: contact.displayName,
        participantIds: [
          if (_currentUserId.isNotEmpty) _currentUserId,
          contact.id,
        ],
        isGroup: false,
      );
      if (!mounted || conversation == null) return;
      _openConversation(conversation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start conversation. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                child: TabBar(
                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: 'Groups'),
                    Tab(text: 'Inbox'),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'connections') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectionsScreen(),
                      ),
                    );
                  } else if (value == 'blocked') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockedUsersScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'connections',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline),
                        SizedBox(width: 12),
                        Text('Connections'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'blocked',
                    child: Row(
                      children: [
                        Icon(Icons.block),
                        SizedBox(width: 12),
                        Text('Blocked Users'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: StudentPageBackground(
          child: BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final loading =
                  state.status == ChatStatus.initial ||
                  state.status == ChatStatus.loading;
              if (loading) {
                return const Padding(
                  padding: AppSpacing.paddingLg,
                  child: ShimmerList(),
                );
              }
              if (state.status == ChatStatus.error) {
                return AppErrorWidget(
                  message:
                      state.errorMessage ?? 'Unable to load conversations.',
                  onRetry: () => context.read<ChatCubit>().loadConversations(),
                );
              }

              final conversations = state.conversations;
              final groups = conversations.where((c) => c.isGroup).toList();
              final inbox = conversations.where((c) => !c.isGroup).toList();

              return TabBarView(
                children: [
                  BrandedRefreshIndicator(
                    onRefresh: () =>
                        context.read<ChatCubit>().loadConversations(),
                    child: _ChatList(
                      items: groups,
                      onTapItem: _openConversation,
                    ),
                  ),
                  BrandedRefreshIndicator(
                    onRefresh: () =>
                        context.read<ChatCubit>().loadConversations(),
                    child: _ChatList(
                      items: inbox,
                      onTapItem: _openConversation,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'New message',
          onPressed: _showComposeOptions,
          child: const Icon(Icons.message),
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
    if (msg.type == MessageType.image) return 'Image';
    if (msg.type == MessageType.file) return 'File';
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
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: EmptyStateWidget(
                  illustration: ChatBubblesIllustration(),
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations yet',
                  subtitle:
                      'Start a conversation with your classmates or teachers.',
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        void openConversation() => onTapItem(item);
        return StaggeredFadeSlide(
          index: index,
          child: Pressable(
            onTap: openConversation,
            enableHaptic: false,
            child: ListTile(
              onTap: null,
              leading: Hero(
                tag: 'chat-avatar-${item.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: ProfileAvatar(
                    profileImagePath: item.avatarPath,
                    fallbackText: item.title,
                  ),
                ),
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapXs,
                  if (item.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '${item.unreadCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
