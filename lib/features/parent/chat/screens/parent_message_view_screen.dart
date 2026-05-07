import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
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
  String? _nextCursor; // oldest loaded message ID for cursor pagination

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Real-time
  StreamSubscription? _msgSub;
  bool _showNewMessageButton = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);

    if (widget.conversationId.isNotEmpty) {
      _msgSub = SocketService().messageNewStream.listen(_onMessageNew);
      SocketService().joinConversation(widget.conversationId);
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    if (widget.conversationId.isNotEmpty) {
      SocketService().leaveConversation(widget.conversationId);
    }
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 80 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  void _onMessageNew(Map<String, dynamic> event) {
    if (event['conversationId'] != widget.conversationId) return;

    final currentUserId = AuthService().currentUser?.id ?? '';
    final senderId = event['senderId'] as String? ?? '';

    // Deduplicate: if we sent this and there's a temp bubble, replace it
    if (senderId == currentUserId) {
      final text = event['text'] as String? ?? '';
      final tempIdx = _messages.indexWhere(
        (m) => (m['id'] as String? ?? '').startsWith('temp-') &&
            m['text'] == text,
      );
      if (tempIdx != -1) {
        setState(() => _messages[tempIdx] = event);
        return;
      }
    }

    // Check for existing message update
    final existingIdx = _messages.indexWhere(
      (m) => m['id'] == event['id'],
    );
    if (existingIdx != -1) {
      setState(() => _messages[existingIdx] = event);
      return;
    }

    // New message from other party
    final isNearBottom = _scrollController.hasClients &&
        (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <=
            100;

    setState(() {
      _messages.add(event);
      if (!isNearBottom) _showNewMessageButton = true;
    });

    if (isNearBottom) _scrollToBottom();
  }

  Future<void> _loadInitial() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _messages = [];
        _hasMore = true;
        _nextCursor = null;
      });

      final msgs = await ApiService().getConversationMessagesPaginated(
        widget.conversationId,
        limit: 30,
      );

      if (!mounted) return;

      // API returns newest-first, reverse to oldest-first for display
      final reversed = msgs.cast<Map<String, dynamic>>().reversed.toList();

      setState(() {
        _messages = reversed;
        _nextCursor = msgs.isNotEmpty ? (msgs.first as Map)['id'] as String? : null;
        _hasMore = msgs.length == 30;
        _loading = false;
      });

      _scrollToBottom(jump: true);
      _markLastRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);

    try {
      final msgs = await ApiService().getConversationMessagesPaginated(
        widget.conversationId,
        before: _nextCursor,
        limit: 30,
      );

      if (!mounted) return;

      final oldExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;

      final older = msgs.cast<Map<String, dynamic>>().reversed.toList();

      setState(() {
        _messages = [...older, ..._messages];
        if (msgs.isNotEmpty) {
          _nextCursor = (msgs.first as Map)['id'] as String?;
        }
        _hasMore = msgs.length == 30;
        _loadingMore = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(
            _scrollController.offset + (newExtent - oldExtent),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _markLastRead() {
    if (_messages.isEmpty || widget.conversationId.isEmpty) return;
    final lastId = _messages.last['id'] as String? ?? '';
    if (lastId.isEmpty) return;
    ApiService().markMessageRead(widget.conversationId, lastId).catchError((_) {});
    SocketService().sendReadUpdate(widget.conversationId, lastId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    _messageController.clear();
    setState(() => _sending = true);

    // Optimistic bubble
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = AuthService().currentUser;
    final optimistic = {
      'id': tempId,
      'conversationId': widget.conversationId,
      'senderId': currentUser?.id ?? '',
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final sent = await ApiService().sendMessage(
        widget.conversationId,
        {'text': text},
      );

      if (!mounted) return;

      final idx = _messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) {
        setState(() {
          _messages[idx] = sent;
          _sending = false;
        });
      } else {
        setState(() => _sending = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _sending = false;
      });
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildBody()),
              _buildMessageInput(),
            ],
          ),
          if (_showNewMessageButton)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _showNewMessageButton = false);
                    _scrollToBottom();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('New messages',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final appBarColor = Color.alphaBlend(
      AppColors.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.07,
      ),
      theme.colorScheme.surface,
    );
    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
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
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.onSurfaceVariant,
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
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load messages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello to start the conversation!',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
        final showDate =
            msgIndex == 0 ||
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
              showTail:
                  msgIndex == _messages.length - 1 ||
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
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C3E)
                  : const Color(0xFFEEEEF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDate(isoString),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
          ),
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
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) const SizedBox(width: 60),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C3E)
                        : const Color(0xFFEEEEF4),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                        isMe ? 18 : (showTail ? 4 : 18),
                      ),
                      bottomRight: Radius.circular(
                        isMe ? (showTail ? 4 : 18) : 18,
                      ),
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
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C3E)
                    : const Color(0xFFEEEEF4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
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
                  color: _sending
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C3E)
                            : const Color(0xFFEEEEF4))
                      : AppColors.primary,
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
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
