import 'package:flutter/material.dart';
import '../models/sync_status_model.dart';
import '../repositories/student_sync_repository.dart';
import '../repositories/mock_student_sync_repository.dart';

class StudentSyncStatusScreen extends StatefulWidget {
  final StudentSyncRepository? repository;

  const StudentSyncStatusScreen({super.key, this.repository});

  @override
  State<StudentSyncStatusScreen> createState() =>
      _StudentSyncStatusScreenState();
}

class _StudentSyncStatusScreenState extends State<StudentSyncStatusScreen> {
  late final StudentSyncRepository _repository;
  List<SyncItemModel> _items = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentSyncRepository();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() => _isLoading = true);
    try {
      final items = await _repository.fetchSyncStatus();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      final items = await _repository.triggerSync();
      if (!mounted) return;
      setState(() => _items = items);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  IconData _statusIcon(SyncItemStatus status) {
    return switch (status) {
      SyncItemStatus.synced => Icons.check_circle,
      SyncItemStatus.pending => Icons.sync_problem,
      SyncItemStatus.error => Icons.error_outline,
    };
  }

  Color _statusColor(SyncItemStatus status) {
    return switch (status) {
      SyncItemStatus.synced => Colors.green,
      SyncItemStatus.pending => Colors.orange,
      SyncItemStatus.error => Colors.red,
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offline Access & Sync',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text('No sync items available.'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item.category),
                                  subtitle: Text(
                                    '${item.description}\nLast synced: ${_formatTime(item.lastSyncedAt)}'
                                    '${item.pendingCount > 0 ? ' • ${item.pendingCount} pending' : ''}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Icon(
                                    _statusIcon(item.status),
                                    color: _statusColor(item.status),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _triggerSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
