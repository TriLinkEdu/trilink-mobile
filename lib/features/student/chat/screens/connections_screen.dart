import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../shared/widgets/student_page_background.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _repository = sl<StudentChatRepository>();
  bool _loading = true;
  List<ConnectionModel> _sent = [];
  List<ConnectionModel> _received = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.fetchConnections();
      setState(() {
        _sent = data['sent'] ?? [];
        _received = data['received'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _acceptConnection(ConnectionModel conn) async {
    try {
      await _repository.acceptConnection(conn.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection accepted!')),
      );
      _loadConnections();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept')),
      );
    }
  }

  Future<void> _rejectConnection(ConnectionModel conn) async {
    try {
      await _repository.rejectConnection(conn.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection rejected')),
      );
      _loadConnections();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Connections'),
      ),
      body: StudentPageBackground(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadConnections)
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: 'Received (${_received.where((c) => c.status == ConnectionStatus.pending).length})'),
                            Tab(text: 'Sent (${_sent.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildReceivedList(),
                              _buildSentList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildReceivedList() {
    final pending = _received.where((c) => c.status == ConnectionStatus.pending).toList();
    
    if (pending.isEmpty) {
      return Center(
        child: Text('No pending requests'),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final conn = pending[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(conn.requesterName?[0] ?? 'U'),
            ),
            title: Text(conn.requesterName ?? 'Unknown'),
            subtitle: Text('Wants to connect'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptConnection(conn),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectConnection(conn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentList() {
    if (_sent.isEmpty) {
      return Center(
        child: Text('No sent requests'),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _sent.length,
      itemBuilder: (context, index) {
        final conn = _sent[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(conn.recipientName?[0] ?? 'U'),
            ),
            title: Text(conn.recipientName ?? 'Unknown'),
            trailing: Chip(
              label: Text(
                conn.status.name.toUpperCase(),
                style: TextStyle(fontSize: 10),
              ),
              backgroundColor: conn.status == ConnectionStatus.accepted
                  ? Colors.green.withOpacity(0.2)
                  : conn.status == ConnectionStatus.rejected
                      ? Colors.red.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }
}
