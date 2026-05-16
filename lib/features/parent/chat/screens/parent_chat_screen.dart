import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/models/conversation_summary.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import 'parent_message_view_screen.dart';

class ParentChatScreen extends StatefulWidget {
  const ParentChatScreen({super.key});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  List<_ContactUser> _adminUsers = [];
  List<_ContactUser> _teacherUsers = [];
  List<ConversationSummary> _conversations = [];

  StreamSubscription? _convUpdateSub;
  StreamSubscription? _msgNewSub;
  String? _openConversationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    _convUpdateSub =
        SocketService().conversationUpdateStream.listen(_onConversationUpdate);
    _msgNewSub = SocketService().messageNewStream.listen(_onMessageNew);
    SocketService().setPresence('online');
  }

  @override
  void dispose() {
    _convUpdateSub?.cancel();
    _msgNewSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onConversationUpdate(Map<String, dynamic> event) {
    final id = event['id'] as String?;
    if (id == null) return;
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    setState(() {
      _conversations[idx] = ConversationSummary.fromJson({
        ..._conversations[idx].toJson(),
        ...event,
      });
    });
  }

  void _onMessageNew(Map<String, dynamic> event) {
    final convId = event['conversationId'] as String?;
    if (convId == null || convId == _openConversationId) return;
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx == -1) return;
    setState(() {
      _conversations[idx] = _conversations[idx].copyWith(
        unreadCount: _conversations[idx].unreadCount + 1,
        lastMessageText: event['text'] as String?,
        lastMessageAt: event['createdAt'] as String?,
      );
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load contacts and existing conversations in parallel
      final results = await Future.wait([
        ApiService().searchUsers(),
        ApiService().getConversations(),
      ]);

      if (!mounted) return;

      final users = results[0] as List<dynamic>;
      final convRaw = results[1] as List<dynamic>;

      final List<_ContactUser> admins = [];
      final List<_ContactUser> teachers = [];

      for (final user in users) {
        final role = user['role'] as String?;
        if (role == 'admin') {
          admins.add(_ContactUser.fromJson(user as Map<String, dynamic>));
        } else if (role == 'teacher') {
          teachers.add(_ContactUser.fromJson(user as Map<String, dynamic>));
        }
      }

      final conversations = convRaw
          .map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>))
          .where((c) => c.type == 'direct')
          .toList();

      setState(() {
        _adminUsers = admins;
        _teacherUsers = teachers;
        _conversations = conversations;
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

  Future<void> _startConversation(_ContactUser user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService().initiateConversation(user.id);
      final conversation = response['conversation'] as Map<String, dynamic>;
      final conversationId = conversation['id'] as String;

      if (!mounted) return;
      Navigator.pop(context);

      setState(() => _openConversationId = conversationId);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParentMessageViewScreen(
            conversationId: conversationId,
            teacherName: user.fullName,
            subject: user.role == 'admin'
                ? 'Administrator'
                : user.subject ?? 'Teacher',
          ),
        ),
      );

      // Reset unread on return
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1 && mounted) {
        setState(() {
          _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
          _openConversationId = null;
        });
      } else {
        setState(() => _openConversationId = null);
      }
      // Refresh to pick up any new conversation
      _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openConversation(ConversationSummary conv) async {
    setState(() => _openConversationId = conv.id);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentMessageViewScreen(
          conversationId: conv.id,
          teacherName: conv.title,
          subject: '',
        ),
      ),
    );

    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx != -1 && mounted) {
      setState(() {
        _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
        _openConversationId = null;
      });
    } else {
      setState(() => _openConversationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildTabView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
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
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: AppColors.primary),
          insets: EdgeInsets.symmetric(horizontal: 24),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Admin'),
                if (_adminUsers.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_adminUsers.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Teachers'),
                if (_teacherUsers.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_teacherUsers.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [_buildAdminTab(), _buildTeachersTab()],
    );
  }

  Widget _buildAdminTab() {
    final recentConvs = _conversations.where((c) {
      final members = [...c.participants, ...c.members];
      return members.any((m) => m.role == 'admin' || m.role == 'superadmin');
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recentConvs.isNotEmpty) ...[
            _sectionLabel('RECENT'),
            const SizedBox(height: 8),
            ...recentConvs.map((c) => _ConversationTile(
                  conv: c,
                  onTap: () => _openConversation(c),
                )),
            const SizedBox(height: 16),
            _sectionLabel('ALL ADMINS'),
            const SizedBox(height: 8),
          ],
          if (_adminUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('No administrators available',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              _adminUsers.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactTile(
                  user: _adminUsers[i],
                  onTap: () => _startConversation(_adminUsers[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    final recentConvs = _conversations.where((c) {
      final members = [...c.participants, ...c.members];
      return members.any((m) => m.role == 'teacher');
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recentConvs.isNotEmpty) ...[
            _sectionLabel('RECENT'),
            const SizedBox(height: 8),
            ...recentConvs.map((c) => _ConversationTile(
                  conv: c,
                  onTap: () => _openConversation(c),
                )),
            const SizedBox(height: 16),
            _sectionLabel('ALL TEACHERS'),
            const SizedBox(height: 8),
          ],
          if (_teacherUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('No teachers available',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              _teacherUsers.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactTile(
                  user: _teacherUsers[i],
                  onTap: () => _startConversation(_teacherUsers[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ContactUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? subject;
  final String? department;
  final String? profileImageFileId;
  final String? profileImagePath;

  _ContactUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.subject,
    this.department,
    this.profileImageFileId,
    this.profileImagePath,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displaySubject {
    if (role == 'admin') return 'Administrator';
    return subject ?? 'Teacher';
  }

  factory _ContactUser.fromJson(Map<String, dynamic> json) {
    // Helper function to handle "null" strings from API
    String? parseNullableString(dynamic value) {
      if (value == null || value == 'null') return null;
      final str = value as String?;
      return str?.trim().isEmpty == true ? null : str?.trim();
    }

    return _ContactUser(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      subject: parseNullableString(json['subject']),
      department: parseNullableString(json['department']),
      profileImageFileId: parseNullableString(json['profileImageFileId']),
      profileImagePath: parseNullableString(json['profileImagePath']),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final _ContactUser user;
  final VoidCallback onTap;

  const _ContactTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.displaySubject,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (user.department != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            user.department!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<Map<String, String>?>(
      future: _getAuthHeaders(),
      builder: (context, snapshot) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage:
              (user.profileImagePath != null &&
                  user.profileImagePath!.isNotEmpty &&
                  snapshot.hasData)
              ? NetworkImage(
                  '${ApiConstants.fileBaseUrl}${user.profileImagePath}',
                  headers: snapshot.data,
                )
              : null,
          child:
              (user.profileImagePath == null || user.profileImagePath!.isEmpty)
              ? Text(
                  _getInitials(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        );
      },
    );
  }

  String _getInitials() {
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await StorageService().accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }
}

// ─── Conversation Tile (existing chats) ──────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationSummary conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${d.month}/${d.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = conv.unreadCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread > 0
                ? AppColors.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant,
            width: unread > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                conv.title.isNotEmpty ? conv.title[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.title,
                          style: TextStyle(
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (conv.lastMessageText != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessageText!,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
