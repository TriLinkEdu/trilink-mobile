import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getBlockedUsers();
      final users = raw.cast<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() {
        _blockedUsers = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // For 403 or other permission errors, show empty list instead of error
      setState(() {
        _blockedUsers = [];
        _error = null;
        _loading = false;
      });
    }
  }

  Future<void> _unblockUser(Map<String, dynamic> user) async {
    final userId =
        user['id'] as String? ??
        user['blockedId'] as String? ??
        user['userId'] as String?;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Unblock this user? They will be able to message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().unblockUser(userId);
      if (!mounted) return;
      setState(
        () => _blockedUsers.removeWhere((u) {
          final id = u['id'] ?? u['blockedId'] ?? u['userId'];
          return id == userId;
        }),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User unblocked')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock: $e'),
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
          'Blocked Users',
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
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadBlockedUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _blockedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No blocked users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Users you block won\'t be able to message you',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _blockedUsers.length,
              itemBuilder: (_, i) {
                final user = _blockedUsers[i];
                final name =
                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                        .trim();
                final role = user['role'] as String? ?? 'User';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                      child: Icon(Icons.block, color: AppColors.error),
                    ),
                    title: Text(
                      name.isNotEmpty ? name : 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _unblockUser(user),
                      tooltip: 'Unblock',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
