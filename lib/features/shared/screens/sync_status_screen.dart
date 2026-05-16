import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';

/// Shared → Sync status dashboard (`GET /sync/student/status`).
///
/// Pull-to-refresh triggers `POST /sync/student/trigger` to refresh
/// caches server-side.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _loading = true;
  bool _triggering = false;
  String? _error;
  Map<String, dynamic> _status = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getStudentSyncStatus();
      if (!mounted) return;
      setState(() {
        _status = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _trigger() async {
    setState(() => _triggering = true);
    try {
      final res = await ApiService().triggerStudentSync();
      if (!mounted) return;
      setState(() => _status = res);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync triggered.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Trigger failed: $e')));
    } finally {
      if (mounted) setState(() => _triggering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ((_status['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync status'),
        actions: [
          IconButton(
            tooltip: 'Trigger sync',
            onPressed: _triggering ? null : _trigger,
            icon: _triggering
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No sync items.')),
                        ),
                      ...items.map(_card),
                    ],
                  ),
                ),
    );
  }

  Widget _card(Map<String, dynamic> i) {
    final status = i['status']?.toString() ?? 'unknown';
    Color color;
    IconData icon;
    switch (status) {
      case 'synced':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_bottom;
        break;
      case 'error':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(i['category']?.toString() ?? '-'),
        subtitle: Text(
          [
            if ((i['description']?.toString() ?? '').isNotEmpty)
              i['description'],
            'Pending: ${i['pendingCount'] ?? 0}/${i['totalCount'] ?? 0}',
            if ((i['lastSyncedAt']?.toString() ?? '').isNotEmpty)
              'Last: ${i['lastSyncedAt'].toString().split('.').first}',
          ].whereType<String>().join('  •  '),
        ),
        trailing: Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
