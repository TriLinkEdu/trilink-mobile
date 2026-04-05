import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';

class TeacherChatConversationScreen extends StatefulWidget {
  final String threadName;
  final String conversationId;
  final bool isParent;

  const TeacherChatConversationScreen({
    super.key,
    required this.threadName,
    this.conversationId = '',
    this.isParent = false,
  });

  @override
  State<TeacherChatConversationScreen> createState() =>
      _TeacherChatConversationScreenState();
}

class _TeacherChatConversationScreenState
    extends State<TeacherChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  List<_ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final msgs = await ApiService().getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs.map((m) {
          final map = m as Map<String, dynamic>;
          final senderMap = map['sender'] as Map<String, dynamic>?;
          final senderName = senderMap != null
              ? '${senderMap['firstName'] ?? ''} ${senderMap['lastName'] ?? ''}'
                    .trim()
              : 'Unknown';
          final senderId =
              senderMap?['id'] as String? ?? map['senderId'] as String? ?? '';
          final currentUserId = AuthService().currentUser?.id ?? '';
          final isSent = senderId == currentUserId;

          final createdAt = map['createdAt'] as String?;
          String time = '';
          String date = 'Today';
          if (createdAt != null) {
            try {
              final dt = DateTime.parse(createdAt).toLocal();
              final now = DateTime.now();
              time =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              if (dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day) {
                date = 'Today';
              } else if (dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day - 1) {
                date = 'Yesterday';
              } else {
                date = '${dt.month}/${dt.day}/${dt.year}';
              }
            } catch (_) {}
          }

          return _ChatMessage(
            sender: isSent ? 'You' : senderName,
            text: map['content'] as String? ?? '',
            time: time,
            isSent: isSent,
            date: date,
          );
        }).toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.conversationId.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(
        _ChatMessage(
          sender: 'You',
          text: text,
          time: 'Sending...',
          isSent: true,
          date: 'Today',
        ),
      );
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await ApiService().sendMessage(widget.conversationId, {'content': text});
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _messages.last = _ChatMessage(
          sender: 'You',
          text: text,
          time:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          isSent: true,
          date: 'Today',
        );
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _sending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.threadName,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final grouped = <String, List<_ChatMessage>>{};
    for (final msg in _messages) {
      grouped.putIfAbsent(msg.date, () => []).add(msg);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(_buildDateDivider(entry.key));
      for (final msg in entry.value) {
        widgets.add(_buildMessageBubble(msg));
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: widgets,
    );
  }

  Widget _buildDateDivider(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isSent = message.isSent;
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isSent
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isSent)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  message.sender,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSent ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                message.time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isSent;
  final String date;

  _ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isSent,
    required this.date,
  });
}
