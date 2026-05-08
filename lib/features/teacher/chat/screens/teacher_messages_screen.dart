import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/conversation_summary.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import 'create_group_screen.dart';
import 'teacher_chat_conversation_screen.dart';

class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ConversationSummary> _conversations = [];
  String _searchQuery = '';

  // Presence map: userId → isOnline
  Map<String, bool> _presenceMap = {};

  // Real-time stream subscriptions
  StreamSubscription? _msgNewSub;
  StreamSubscription? _convUpdateSub;
  StreamSubscription? _presenceSub;

  // Track the currently open conversation so we don't badge it
  String? _openConversationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();

    // Subscribe to real-time events
    _msgNewSub = SocketService().messageNewStream.listen(_onMessageNew);
    _convUpdateSub =
        SocketService().conversationUpdateStream.listen(_onConversationUpdate);
    _presenceSub =
        SocketService().presenceUpdateStream.listen(_onPresenceUpdate);

    // Announce presence
    SocketService().setPresence('online');
  }

  @override
  void dispose() {
    _msgNewSub?.cancel();
    _convUpdateSub?.cancel();
    _presenceSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Real-time handlers ────────────────────────────────────────────────────

  void _onMessageNew(Map<String, dynamic> event) {
    final conversationId = event['conversationId'] as String?;
    if (conversationId == null) return;
    // Only badge if this conversation is not currently open
    if (conversationId == _openConversationId) return;

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    setState(() {
      _conversations[idx] =
          _conversations[idx].copyWith(
            unreadCount: _conversations[idx].unreadCount + 1,
            lastMessageText: event['text'] as String? ??
                _conversations[idx].lastMessageText,
            lastMessageAt: event['createdAt'] as String? ??
                _conversations[idx].lastMessageAt,
          );
    });
  }

  void _onConversationUpdate(Map<String, dynamic> event) {
    final conversationId = event['id'] as String?;
    if (conversationId == null) return;

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    setState(() {
      _conversations[idx] = ConversationSummary.fromJson({
        ..._conversations[idx].toJson(),
        ...event,
      });
    });
  }

  void _onPresenceUpdate(Map<String, dynamic> event) {
    final userId = event['userId'] as String?;
    final isOnline = event['isOnline'] as bool? ?? false;
    if (userId == null) return;

    setState(() {
      _presenceMap[userId] = isOnline;
    });
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService().getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = raw
            .map((c) =>
                ConversationSummary.fromJson(c as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Filtering / categorisation ────────────────────────────────────────────

  List<ConversationSummary> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) {
      return c.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ConversationSummary> _getConversationsByType(String type) {
    final filtered = _filteredConversations;

    // Helper: get all user roles from a conversation's member/participant data
    List<String> _memberRoles(ConversationSummary c) {
      final all = [...c.participants, ...c.members];
      return all.map((m) => m.role.toLowerCase()).toList();
    }

    switch (type) {
      case 'student':
        return filtered.where((c) {
          if (c.type != 'direct') return false;
          final roles = _memberRoles(c);
          // Has a student role member
          if (roles.contains('student')) return true;
          // No parent/admin role — default direct chats go to Students
          if (!roles.contains('parent') &&
              !roles.contains('admin') &&
              !roles.contains('superadmin')) return true;
          return false;
        }).toList();

      case 'parent':
        return filtered.where((c) {
          if (c.type != 'direct') return false;
          final roles = _memberRoles(c);
          return roles.contains('parent');
        }).toList();

      case 'admin':
        return filtered.where((c) {
          if (c.type != 'direct') return false;
          final roles = _memberRoles(c);
          return roles.contains('admin') || roles.contains('superadmin');
        }).toList();

      case 'group':
        return filtered.where((c) => c.type == 'group').toList();

      default:
        return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  String _badgeLabel(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatList('student'),
                  _buildChatList('parent'),
                  _buildChatList('admin'),
                  _buildChatList('group'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          _loadData();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            backgroundImage: const NetworkImage(
              'https://i.pravatar.cc/80?img=32',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: [
            _buildTab(Icons.school_outlined, 'Students'),
            _buildTab(Icons.people_outline, 'Parents'),
            _buildTab(Icons.admin_panel_settings_outlined, 'Admin'),
            _buildTab(Icons.group_outlined, 'Groups'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search students, parents, or groups...',
            hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }

  Widget _buildChatList(String type) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final threads = _getConversationsByType(type);
    if (threads.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No conversations yet',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: threads.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: _buildSectionLabel('CONVERSATIONS'),
            );
          }
          final summary = threads[index - 1];
          return _buildConversationTile(summary);
        },
      ),
    );
  }

  Widget _buildConversationTile(ConversationSummary summary) {
    final isGroup = summary.type == 'group';
    final members = summary.members.isNotEmpty
        ? summary.members
        : summary.participants;

    // Determine participant ID for presence (first non-self member in direct)
    String? participantId;
    if (!isGroup && members.isNotEmpty) {
      participantId = members.first.id;
    }

    final isOnline =
        participantId != null && (_presenceMap[participantId] == true);
    final unread = summary.unreadCount;
    final badge = _badgeLabel(unread);

    return GestureDetector(
      onTap: () async {
        // Mark as open so new messages don't badge this conversation
        setState(() => _openConversationId = summary.id);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherChatConversationScreen(
              threadName: summary.title,
              conversationId: summary.id,
            ),
          ),
        );

        // Reset unread count and clear open conversation tracker
        final idx = _conversations.indexWhere((c) => c.id == summary.id);
        if (idx != -1 && mounted) {
          setState(() {
            _conversations[idx] =
                _conversations[idx].copyWith(unreadCount: 0);
            _openConversationId = null;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar with optional online dot
            Stack(
              children: [
                _buildAvatar(summary, members, isGroup),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          summary.title,
                          style: TextStyle(
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(summary.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary.lastMessageText ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: unread > 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
  }

  Widget _buildAvatar(
    ConversationSummary summary,
    List<ConversationMember> members,
    bool isGroup,
  ) {
    if (isGroup) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        child: Icon(Icons.group, color: AppColors.primary, size: 22),
      );
    }

    // Direct conversation — try to show profile image
    final firstMember = members.isNotEmpty ? members.first : null;
    final imageFileId = firstMember?.profileImageFileId;

    if (imageFileId != null && imageFileId.isNotEmpty) {
      final imageUrl =
          '${ApiConstants.fileBaseUrl}/api/files/$imageFileId/download';
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // Fallback: initials avatar
    final initials = firstMember != null
        ? '${firstMember.firstName.isNotEmpty ? firstMember.firstName[0] : ''}${firstMember.lastName.isNotEmpty ? firstMember.lastName[0] : ''}'
            .toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}
