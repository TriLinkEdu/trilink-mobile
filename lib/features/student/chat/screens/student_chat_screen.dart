import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
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
    // Optimistically clear unread badge before network round-trip
    if (conversation.unreadCount > 0) {
      cubit.clearUnread(conversation.id);
    }
    // Determine partnerId for DMs (the other participant)
    String? partnerId;
    if (!conversation.isGroup && conversation.participantIds.length == 2) {
      partnerId = conversation.participantIds.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => conversation.participantIds.first,
      );
    }
    Navigator.of(context)
        .pushNamed(
          RouteNames.studentChatConversation,
          arguments: {
            'conversationId': conversation.id,
            'title': conversation.title,
            'isGroup': conversation.isGroup,
            'avatarPath': conversation.avatarPath,
            'partnerId': partnerId,
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
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        primary: false,
        backgroundColor: theme.colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Groups'),
                Tab(text: 'Inbox'),
              ],
            ),
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
                      isGroup: true,
                    ),
                  ),
                  BrandedRefreshIndicator(
                    onRefresh: () =>
                        context.read<ChatCubit>().loadConversations(),
                    child: _ChatList(
                      items: inbox,
                      onTapItem: _openConversation,
                      isGroup: false,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow(theme.colorScheme.primary),
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            tooltip: 'New message',
            onPressed: _showComposeOptions,
            child: const Icon(Icons.maps_ugc_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final List<ChatConversationModel> items;
  final ValueChanged<ChatConversationModel> onTapItem;
  final bool isGroup;

  const _ChatList({required this.items, required this.onTapItem, this.isGroup = false});

  String _previewText(ChatConversationModel conversation) {
    final msg = conversation.lastMessage;
    if (msg == null) return 'No messages yet';
    if (msg.type == MessageType.image) return '📷 Image';
    if (msg.type == MessageType.file) return '📎 File';
    return msg.content;
  }

  String _timeLabel(ChatConversationModel conversation) {
    final msg = conversation.lastMessage;
    if (msg == null) return '';
    final diff = DateTime.now().difference(msg.timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d';
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
              child: Center(
                  child: EmptyStateWidget(
                    illustration: ChatBubblesIllustration(),
                    icon: Icons.chat_bubble_outline_rounded,
                    title: isGroup ? 'No groups yet' : 'No messages yet',
                    subtitle: isGroup 
                        ? 'Join or create a study group.'
                        : 'Start a conversation with your classmates or teachers.',
                    actionLabel: isGroup ? 'Create Group' : 'Find Connections',
                    onAction: () {
                      if (isGroup) {
                        // Action could be showNewGroupDialog, but requires passing from parent.
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                        );
                      }
                    },
                  ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        void openConversation() => onTapItem(item);
        final hasUnread = item.unreadCount > 0;
        
        return InkWell(
          onTap: openConversation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'chat-avatar-${item.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: ProfileAvatar(
                      profileImagePath: item.avatarPath,
                      fallbackText: item.title,
                      radius: 28,
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            _timeLabel(item),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _previewText(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            AppSpacing.hGapSm,
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: AppRadius.borderFull,
                                boxShadow: AppShadows.glow(theme.colorScheme.primary),
                              ),
                              child: Text(
                                '${item.unreadCount}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
