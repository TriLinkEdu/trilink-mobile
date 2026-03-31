import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherChatConversationScreen extends StatefulWidget {
  final String threadName;
  final bool isParent;

  const TeacherChatConversationScreen({
    super.key,
    required this.threadName,
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

  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.isParent ? _parentMessages() : _groupMessages();
  }

  List<_ChatMessage> _groupMessages() {
    return [
      _ChatMessage(
        sender: 'Ahmed Al-Farsi',
        text: 'Good morning! Will we have the lab session today?',
        time: '9:00 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Yes, the lab session is confirmed. Please bring your lab coats and safety goggles.',
        time: '9:05 AM',
        isSent: true,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'Sara Mohammed',
        text: 'Got it! Thank you for the reminder.',
        time: '9:08 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Also, please review Chapter 5 before the session. We\'ll be discussing the practical applications.',
        time: '9:12 AM',
        isSent: true,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'Omar Hassan',
        text: 'Is the assignment due date still Friday?',
        time: '9:20 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Yes, the assignment deadline remains Friday at 11:59 PM. No extensions will be given.',
        time: '9:25 AM',
        isSent: true,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'Fatima Noor',
        text: 'Can we work in pairs for the lab report?',
        time: '10:00 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Yes, pairs are allowed for the lab report. Make sure both names are on the submission.',
        time: '10:05 AM',
        isSent: true,
        date: 'Today',
      ),
    ];
  }

  List<_ChatMessage> _parentMessages() {
    return [
      _ChatMessage(
        sender: 'Parent',
        text:
            'Hello, I wanted to ask about my child\'s recent test performance.',
        time: '8:30 AM',
        isSent: false,
        date: 'Yesterday',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Good morning! Your child did well overall. There are a few areas we can work on together.',
        time: '8:45 AM',
        isSent: true,
        date: 'Yesterday',
      ),
      _ChatMessage(
        sender: 'Parent',
        text: 'That\'s great to hear. What areas need improvement?',
        time: '8:50 AM',
        isSent: false,
        date: 'Yesterday',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Mainly problem-solving in math word problems. I\'d recommend some extra practice at home.',
        time: '9:00 AM',
        isSent: true,
        date: 'Yesterday',
      ),
      _ChatMessage(
        sender: 'Parent',
        text: 'Thank you! I\'ll make sure to help with that.',
        time: '9:10 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Wonderful. I\'ll also send home a worksheet packet for additional practice.',
        time: '9:15 AM',
        isSent: true,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'Parent',
        text: 'That would be very helpful. Is there a parent-teacher meeting soon?',
        time: '9:30 AM',
        isSent: false,
        date: 'Today',
      ),
      _ChatMessage(
        sender: 'You',
        text:
            'Yes, next Thursday at 4 PM. I\'ll send the details via the school app.',
        time: '9:35 AM',
        isSent: true,
        date: 'Today',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.threadName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
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
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  setState(() {
                    _messages.add(
                      _ChatMessage(
                        sender: 'You',
                        text: _messageController.text.trim(),
                        time: 'Now',
                        isSent: true,
                        date: 'Today',
                      ),
                    );
                    _messageController.clear();
                  });
                }
              },
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
