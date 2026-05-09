import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/conversation_summary.dart';
import '../../../../features/auth/services/auth_service.dart';

class ParentConversationInfoScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ParentConversationInfoScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<ParentConversationInfoScreen> createState() =>
      _ParentConversationInfoScreenState();
}

class _ParentConversationInfoScreenState
    extends State<ParentConversationInfoScreen> {
  bool _loading = true;
  String? _error;
  List<ConversationMember> _members = [];
  bool _isBlocked = false;
  bool _blockedMe = false;
  String? _otherUserId;
  List<dynamic> _media = [];

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
      final results = await Future.wait([
        ApiService().getConversationMembers(widget.conversationId),
        ApiService().getConversationMedia(widget.conversationId),
        ApiService().getConversation(widget.conversationId),
      ]);

      final rawMembers = results[0] as List<dynamic>;
      final mediaRaw = results[1] as List<dynamic>;
      final convRaw = results[2] as Map<String, dynamic>;

      final members = rawMembers
          .map((m) => ConversationMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // For direct conversations, find the other user (NOT current user)
      final currentUserId = AuthService().currentUser?.id ?? '';
      final convMembers = (convRaw['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final convParticipants = (convRaw['participants'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final all = [...convMembers, ...convParticipants];

      String? otherUserId;
      for (final m in all) {
        final id = m['id'] as String? ?? m['userId'] as String? ?? '';
        if (id.isNotEmpty && id != currentUserId) {
          otherUserId = id;
          break;
        }
      }

      final isBlocked = convRaw['blockedByMe'] as bool? ?? false;
      final blockedMe = convRaw['blockedMe'] as bool? ?? false;

      if (!mounted) return;
      setState(() {
        _members = members;
        _otherUserId = otherUserId;
        _isBlocked = isBlocked;
        _blockedMe = blockedMe;
        _media = mediaRaw;
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

  Future<void> _toggleBlock() async {
    // Validate other user ID exists and is not empty
    if (_otherUserId == null || _otherUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to block: User information missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_blockedMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are blocked by this user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
    if (confirmed != true) return;
    try {
      if (_isBlocked) {
        await ApiService().unblockUser(_otherUserId!);
      } else {
        await ApiService().blockUser(_otherUserId!);
      }
      if (!mounted) return;
      setState(() => _isBlocked = !_isBlocked);
      
      final message = _isBlocked ? 'User blocked successfully' : 'User unblocked successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
        ),
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conversation Info',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
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
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.person,
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
                            'Direct Message',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              _blockedMe
                                  ? Icons.block
                                  : _isBlocked
                                      ? Icons.check_circle
                                      : Icons.block_outlined,
                              color: _blockedMe
                                  ? AppColors.error
                                  : _isBlocked
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                            title: Text(
                              _blockedMe
                                  ? 'You are blocked by this user'
                                  : _isBlocked
                                      ? 'Unblock User'
                                      : 'Block User',
                              style: TextStyle(
                                color: _blockedMe
                                    ? AppColors.error
                                    : _isBlocked
                                        ? AppColors.success
                                        : AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: _blockedMe ? null : _toggleBlock,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Members
                    Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _members.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No members',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _members.length,
                              itemBuilder: (_, i) {
                                final member = _members[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(member.fullName),
                                  subtitle: Text(
                                    member.role.toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Media
                    if (_media.isNotEmpty) ...[
                      Text(
                        'Shared Media (${_media.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _media.take(9).length,
                        itemBuilder: (_, i) {
                          final item = _media[i] as Map<String, dynamic>?;
                          final type = item?['mediaType'] as String? ?? '';
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                type.contains('image')
                                    ? Icons.image
                                    : type.contains('video')
                                        ? Icons.video_library
                                        : Icons.file_present,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
    );
  }
}
