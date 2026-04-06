import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';

class ParentMessageViewScreen extends StatefulWidget {
  final String conversationId;
  final String teacherName;
  final String subject;

  const ParentMessageViewScreen({
    super.key,
    required this.conversationId,
    this.teacherName = 'Unknown',
    this.subject = '',
  });

  @override
  State<ParentMessageViewScreen> createState() =>
      _ParentMessageViewScreenState();
}

class _ParentMessageViewScreenState extends State<ParentMessageViewScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _sending = false;

  // Messages stored oldest-first for display (index 0 = oldest)
  List<Map<String, dynamic>> _messages = [];
  int _skip = 0;
  static const int _pageSize = 30;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near the top
    if (_scrollController.position.pixels <= 80 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _skip = 0;
        _messages = [];
        _hasMore = true;
      });

      final msgs = await ApiService().getConversationMessages(
        widget.conversationId,
        limit: _pageSize,
        skip: 0,
      );

      if (!mounted) return;

      // API returns newest-first, reverse to oldest-first for display
      final reversed = msgs.cast<Map<String, dynamic>>().reversed.toList();

      setState(() {
        _messages = reversed;
        _skip = msgs.length;
        _hasMore = msgs.length == _pageSize;
        _loading = false;
      });

      _scrollToBottom(jump: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final msgs = await ApiService().getConversationMessages(
        widget.conversationId,
        limit: _pageSize,
        skip: _skip,
      );

      if (!mounted) return;

      // Preserve scroll position when prepending older messages
      final oldMaxExtent = _scrollController.position.maxScrollExtent;

      final older = msgs.cast<Map<String, dynamic>>().reversed.toList();

      setState(() {
        _messages = [...older, ..._messages];
        _skip += msgs.length;
        _hasMore = msgs.length == _pageSize;
        _loadingMore = false;
      });

      // Restore scroll position so user stays at same message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          final diff = newMaxExtent - oldMaxExtent;
          _scrollController.jumpTo(_scrollController.offset + diff);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    _messageController.clear();
    setState(() => _sending = true);

    try {
      final sent = await ApiService().sendMessage(
        widget.conversationId,
        {'text': text},
      );

      if (!mounted) return;

      // Optimistically append the sent message
      setState(() {
        _messages.add(sent);
        _skip += 1;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Restore text on failure
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              _getInitials(widget.teacherName),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subject.isNotEmpty)
                  Text(
                    widget.subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Could not load messages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadInitial,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello to start the conversation!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return _buildMessageList();
  }

  Widget _buildMessageList() {
    final currentUserId = AuthService().currentUser?.id ?? '';

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the top
        if (_loadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msgIndex = _loadingMore ? index - 1 : index;
        final msg = _messages[msgIndex];
        final senderId = msg['senderId'] as String? ?? '';
        final text = msg['text'] as String? ?? '';
        final createdAt = msg['createdAt'] as String? ?? '';
        final isMe = senderId == currentUserId;

        // Show date separator if needed
        final showDate = msgIndex == 0 ||
            _isDifferentDay(
              _messages[msgIndex - 1]['createdAt'] as String? ?? '',
              createdAt,
            );

        return Column(
          children: [
            if (showDate) _buildDateSeparator(createdAt),
            _buildMessageBubble(
              text: text,
              time: createdAt,
              isMe: isMe,
              showTail: msgIndex == _messages.length - 1 ||
                  (_messages[msgIndex + 1]['senderId'] != senderId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(String isoString) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDate(isoString),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
    required bool showTail,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: showTail ? 8 : 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) const SizedBox(width: 60),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isMe ? 18 : (showTail ? 4 : 18)),
                      bottomRight:
                          Radius.circular(isMe ? (showTail ? 4 : 18) : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                if (showTail) ...[
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isMe) const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14.5),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending ? Colors.grey.shade300 : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: _sending
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: _sending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.grey.shade600),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool _isDifferentDay(String iso1, String iso2) {
    try {
      final d1 = DateTime.parse(iso1).toLocal();
      final d2 = DateTime.parse(iso2).toLocal();
      return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(date.year, date.month, date.day);
      final diff = today.difference(msgDay).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
