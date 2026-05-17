import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../shared/widgets/student_page_background.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _repository = sl<StudentChatRepository>();
  bool _loading = true;
  List<BlockedUserModel> _blocked = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.fetchBlockedUsers();
      setState(() {
        _blocked = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unblock(BlockedUserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock User?'),
        content: Text('Unblock ${user.blockedName ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.unblockUser(user.blockedId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User unblocked')),
        );
        _loadBlocked();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
      ),
      body: StudentPageBackground(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadBlocked)
                : _blocked.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No blocked users'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _blocked.length,
                        itemBuilder: (context, index) {
                          final user = _blocked[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(user.blockedName?[0] ?? 'U'),
                              ),
                              title: Text(user.blockedName ?? 'Unknown'),
                              trailing: OutlinedButton(
                                onPressed: () => _unblock(user),
                                child: Text('Unblock'),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
