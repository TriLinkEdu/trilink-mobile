import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/conversation_summary.dart';
import 'media_gallery_screen.dart';

class ConversationInfoScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ConversationInfoScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<ConversationInfoScreen> createState() =>
      _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends State<ConversationInfoScreen> {
  bool _loading = true;
  String? _error;
  List<ConversationMember> _members = [];
  bool _isBlocked = false;
  String? _otherUserId;
  bool _isGroup = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getConversationMembers(widget.conversationId);
      final members = raw
          .map((m) => ConversationMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // Determine if group
      final conv = await ApiService().getConversation(widget.conversationId);
      final isGroup = (conv['type'] as String? ?? '') == 'group';

      // For direct conversations, find the other user
      String? otherUserId;
      if (!isGroup && members.isNotEmpty) {
        otherUserId = members.first.id;
      }

      // Check block status
      bool isBlocked = false;
      if (otherUserId != null) {
        final blocked = await ApiService().getBlockedUsers();
        isBlocked = blocked.any((b) {
          final id = b is Map ? b['id'] ?? b['blockedId'] : null;
          return id == otherUserId;
        });
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _isGroup = isGroup;
        _otherUserId = otherUserId;
        _isBlocked = isBlocked;
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

  Future<void> _removeMember(ConversationMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.fullName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().removeConversationMember(widget.conversationId, member.id);
      setState(() => _members.removeWhere((m) => m.id == member.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _addMember() async {
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Search by name...'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
    if (query == null || query.isEmpty) return;

    try {
      final users = await ApiService().searchUsers(q: query);
      if (!mounted) return;
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No users found')),
        );
        return;
      }
      // Show user picker
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i] as Map<String, dynamic>;
                final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                return ListTile(
                  title: Text(name),
                  subtitle: Text(u['role'] as String? ?? ''),
                  onTap: () => Navigator.pop(ctx, u),
                );
              },
            ),
          ),
        ),
      );
      if (selected == null) return;
      final userId = selected['id'] as String? ?? '';
      await ApiService().addConversationMember(widget.conversationId, userId);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleBlock() async {
    final action = _isBlocked ? 'Unblock' : 'Block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action User'),
        content: Text(
          _isBlocked
              ? 'Unblock this user? They will be able to message you again.'
              : 'Block this user? They will not be able to message you.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || _otherUserId == null) return;
    try {
      if (_isBlocked) {
        await ApiService().unblockUser(_otherUserId!);
      } else {
        await ApiService().blockUser(_otherUserId!);
      }
      setState(() => _isBlocked = !_isBlocked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conversation Info',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isGroup)
            IconButton(
              icon: Icon(Icons.person_add_outlined, color: theme.colorScheme.onSurface),
              onPressed: _addMember,
              tooltip: 'Add Member',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(
                              _isGroup ? Icons.group : Icons.person,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.conversationTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isGroup ? 'Group · ${_members.length} members' : 'Direct Message',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Media gallery link
                    _buildListTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Media & Files',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaGalleryScreen(
                            conversationId: widget.conversationId,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Members section
                    Text(
                      'MEMBERS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._members.map((member) => _buildMemberTile(member)),

                    // Block/Unblock (direct only)
                    if (!_isGroup && _otherUserId != null) ...[
                      const SizedBox(height: 16),
                      _buildListTile(
                        icon: _isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                        title: _isBlocked ? 'Unblock User' : 'Block User',
                        color: _isBlocked ? AppColors.primary : AppColors.error,
                        onTap: _toggleBlock,
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildMemberTile(ConversationMember member) {
    final theme = Theme.of(context);
    final initials =
        '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}'
            .toUpperCase();
    return GestureDetector(
      onLongPress: _isGroup ? () => _removeMember(member) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_isGroup)
              Icon(Icons.touch_app_outlined,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: c,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
