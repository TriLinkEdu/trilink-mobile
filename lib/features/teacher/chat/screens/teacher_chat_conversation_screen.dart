import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../features/auth/services/auth_service.dart';
import 'conversation_info_screen.dart';

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
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = true;
  String? _error;
  List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _uploading = false;
  String? _blockedNotice;

  // Pagination
  String? _nextCursor;
  bool _loadingMore = false;
  bool _hasMore = true;

  // Reply
  ChatMessage? _replyTo;

  // New message button
  bool _showNewMessageButton = false;

  // Typing
  Timer? _typingTimer;
  Map<String, bool> _typingUsers = {};
  final Map<String, Timer> _typingAutoHideTimers = {};

  // Edit
  String _editingMessageId = '';

  // Read receipts — tracks which sent messages have been read by others
  final Map<String, bool> _readByMap = {};

  // Real-time subscriptions
  StreamSubscription? _msgSub;
  StreamSubscription? _msgUpdateSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _presenceSub;

  // Presence — other participant's online status
  bool _otherUserOnline = false;
  String? _otherUserId;

  // Message key map for scroll-to-message
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);

    if (widget.conversationId.isNotEmpty) {
      _msgSub = SocketService().messageNewStream.listen(_onMessageNew);
      _msgUpdateSub = SocketService().messageUpdateStream.listen(
        _onMessageUpdate,
      );
      _typingSub = SocketService().typingUpdateStream.listen(_onTypingUpdate);
      _readSub = SocketService().readUpdateStream.listen(_onReadUpdate);
      _presenceSub = SocketService().presenceUpdateStream.listen(
        _onPresenceUpdate,
      );
      SocketService().joinConversation(widget.conversationId);
      _loadPresence();
    }
  }

  // ── Scroll listener for pagination ───────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) {
      _loadMoreMessages();
    }
  }

  // ── Real-time handlers ────────────────────────────────────────────────────

  void _onMessageNew(Map<String, dynamic> event) {
    _handleIncomingMessageEvent(event);
  }

  void _onMessageUpdate(Map<String, dynamic> event) {
    _handleIncomingMessageEvent(event);
  }

  void _handleIncomingMessageEvent(Map<String, dynamic> event) {
    final payload = _normalizeIncomingMessagePayload(event);
    if (payload == null || payload['id'] == null) return;
    if (payload['conversationId'] != widget.conversationId) return;
    final incoming = ChatMessage.fromJson(payload);
    if (incoming.id.isEmpty) return;

    // 1. Check if this is an update to an existing message (edit/delete/reaction)
    final existingIdx = _messages.indexWhere((m) => m.id == incoming.id);
    if (existingIdx != -1) {
      setState(() => _messages[existingIdx] = incoming);
      return;
    }

    // 2. Check if there's an optimistic (temp) message from us with the same text
    //    — this happens when the WebSocket event arrives before or after the HTTP
    //    response replaces the temp bubble. Avoid duplicating.
    final currentUserId = AuthService().currentUser?.id ?? '';
    if (incoming.senderId == currentUserId) {
      final tempIdx = _messages.indexWhere(
        (m) => m.id.startsWith('temp-') && m.text == incoming.text,
      );
      if (tempIdx != -1) {
        // Replace the optimistic bubble with the confirmed one
        setState(() => _messages[tempIdx] = incoming);
        return;
      }
    }

    // New message — append
    final isNearBottom =
        _scrollController.hasClients &&
        (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <=
            100;

    setState(() {
      _messages.add(incoming);
      if (!isNearBottom) _showNewMessageButton = true;
    });

    if (isNearBottom) _scrollToBottom();
    _markLastMessageRead();
  }

  Map<String, dynamic>? _normalizeIncomingMessagePayload(
    Map<String, dynamic> event,
  ) {
    final nested = event['message'];
    if (nested is Map) {
      final payload = Map<String, dynamic>.from(nested);
      payload['conversationId'] =
          payload['conversationId'] ?? event['conversationId'];
      return payload;
    }
    return event;
  }

  void _onTypingUpdate(Map<String, dynamic> event) {
    if (event['conversationId'] != widget.conversationId) return;
    final userId = event['userId'] as String? ?? '';
    final isTyping = event['isTyping'] as bool? ?? false;
    if (userId.isEmpty) return;

    _typingAutoHideTimers[userId]?.cancel();
    setState(() => _typingUsers[userId] = isTyping);

    if (isTyping) {
      _typingAutoHideTimers[userId] = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _typingUsers[userId] = false);
      });
    }
  }

  void _onReadUpdate(Map<String, dynamic> event) {
    if (event['conversationId'] != widget.conversationId) return;
    final userId = event['userId'] as String? ?? '';
    final messageId =
        event['lastReadMessageId'] as String? ??
        event['messageId'] as String? ??
        '';
    if (userId.isEmpty || messageId.isEmpty) return;

    final currentUserId = AuthService().currentUser?.id ?? '';
    if (userId == currentUserId) return; // ignore own read events

    // Mark all sent messages up to and including messageId as read
    bool found = false;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (!found && m.id == messageId) found = true;
      if (found && m.senderId == currentUserId) {
        _readByMap[m.id] = true;
      }
      if (i == 0) break;
    }
    setState(() {});
  }

  void _onPresenceUpdate(Map<String, dynamic> event) {
    final userId = event['userId'] as String? ?? '';
    final isOnline = event['isOnline'] as bool? ?? false;
    if (_otherUserId != null && userId == _otherUserId) {
      setState(() => _otherUserOnline = isOnline);
    }
  }

  Future<void> _loadPresence() async {
    try {
      final conv = await ApiService().getConversation(widget.conversationId);
      final currentUserId = AuthService().currentUser?.id ?? '';
      final members = (conv['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final participants = (conv['participants'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final all = [...members, ...participants];

      String otherId = '';
      for (final m in all) {
        final id = m['id'] as String? ?? m['userId'] as String? ?? '';
        if (id.isNotEmpty && id != currentUserId) {
          otherId = id;
          break;
        }
      }
      if (otherId.isEmpty) return;

      _otherUserId = otherId;
      final blockedByMe = conv['blockedByMe'] as bool? ?? false;
      final blockedMe = conv['blockedMe'] as bool? ?? false;
      _blockedNotice = blockedMe
          ? 'You are blocked by this user'
          : blockedByMe
          ? 'You blocked this user'
          : null;

      final presenceMap = await ApiService().getUserPresence([otherId]);
      if (!mounted) return;

      // Backend returns { userId: { isOnline: bool, lastSeenAt: string } }
      final userPresence = presenceMap[otherId] as Map<String, dynamic>?;
      final isOnline = userPresence?['isOnline'] as bool? ?? false;
      setState(() => _otherUserOnline = isOnline);
    } catch (_) {
      // Non-fatal
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    if (widget.conversationId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final raw = await ApiService().getConversationMessagesPaginated(
        widget.conversationId,
        limit: 50,
      );
      if (!mounted) return;

      // API returns newest-first; reverse for display (oldest at top)
      final msgs = raw.reversed
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _messages = msgs;
        _nextCursor = raw.isNotEmpty
            ? (raw.first as Map)['id'] as String?
            : null;
        _hasMore = raw.length == 50;
        _loading = false;
      });
      _scrollToBottom(jump: true);
      _markLastMessageRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);

    try {
      final raw = await ApiService().getConversationMessagesPaginated(
        widget.conversationId,
        before: _nextCursor,
        limit: 50,
      );
      if (!mounted) return;

      final older = raw.reversed
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      final oldExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;

      setState(() {
        _messages = [...older, ..._messages];
        if (raw.isNotEmpty) {
          _nextCursor = (raw.first as Map)['id'] as String?;
        }
        _hasMore = raw.length == 50;
        _loadingMore = false;
      });

      // Restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(
            _scrollController.offset + (newExtent - oldExtent),
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _markLastMessageRead() {
    if (_messages.isEmpty || widget.conversationId.isEmpty) return;
    final lastId = _messages.last.id;
    if (lastId.isEmpty) return;
    ApiService()
        .markMessageRead(widget.conversationId, lastId)
        .catchError((_) {});
    SocketService().sendReadUpdate(widget.conversationId, lastId);
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage({String? mediaFileId}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && mediaFileId == null) return;
    if (widget.conversationId.isEmpty) return;

    final replyToId = _replyTo?.id;
    _messageController.clear();
    final replySnapshot = _replyTo;
    setState(() {
      _replyTo = null;
      _sending = true;
    });

    // Optimistic bubble
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = AuthService().currentUser;
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      senderId: currentUser?.id ?? '',
      senderName: currentUser?.fullName ?? 'You',
      text: text.isNotEmpty ? text : '[Uploading...]',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      replyToId: replyToId,
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final body = <String, dynamic>{
        if (text.isNotEmpty) 'text': text,
        if (mediaFileId != null) 'mediaFileId': mediaFileId,
        if (replyToId != null) 'replyToId': replyToId,
      };
      final result = await ApiService().sendMessage(
        widget.conversationId,
        body,
      );
      if (!mounted) return;
      final confirmed = ChatMessage.fromJson(result);
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && mounted) {
        setState(() {
          _messages[idx] = confirmed;
          _blockedNotice = null;
          _sending = false;
        });
      } else if (mounted) {
        // Temp was already replaced by the WebSocket event — just clear sending
        setState(() {
          _blockedNotice = null;
          _sending = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final isBlockedError =
          e is ApiException &&
          e.statusCode == 403 &&
          e.message.toLowerCase().contains('blocked');
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _sending = false;
        _replyTo = replySnapshot;
        if (isBlockedError) {
          _blockedNotice = e.message;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlockedError
                ? 'This conversation is blocked'
                : 'Failed to send: $e',
          ),
          action: isBlockedError
              ? SnackBarAction(label: 'Check', onPressed: _openConversationInfo)
              : SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _sendMessage(mediaFileId: mediaFileId),
                ),
        ),
      );
    }
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  void _handleTyping(String value) {
    if (widget.conversationId.isEmpty) return;
    if (_typingTimer == null || !_typingTimer!.isActive) {
      SocketService().sendTyping(widget.conversationId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      SocketService().sendTyping(widget.conversationId, false);
    });
  }

  // ── Media upload ──────────────────────────────────────────────────────────

  Future<void> _pickMedia(String source) async {
    try {
      dynamic file;
      if (source == 'gallery') {
        file = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else if (source == 'camera') {
        file = await ImagePicker().pickImage(source: ImageSource.camera);
      } else {
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.isNotEmpty) {
          file = result.files.first;
        }
      }
      if (file == null) return;

      // Size check
      int? size;
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        size = bytes.length;
      } else if (file.size != null) {
        size = file.size as int;
      }
      if (size != null && size > 50 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 50 MB)')),
        );
        return;
      }

      setState(() => _uploading = true);
      final mediaFileId = await ApiService().uploadChatMedia(file);
      if (!mounted) return;
      setState(() => _uploading = false);
      await _sendMessage(mediaFileId: mediaFileId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  // ── Message actions ───────────────────────────────────────────────────────

  void _showMessageActions(ChatMessage message) {
    final currentUserId = AuthService().currentUser?.id ?? '';
    final isOwn = message.senderId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Emoji reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleReaction(message, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = message);
              },
            ),
            if (isOwn && !message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(message);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    try {
      await ApiService().toggleReaction(
        widget.conversationId,
        message.id,
        emoji,
      );
      // The server emits message:update with updated reactions
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to react: $e')));
    }
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editController.text = message.text;
    });
  }

  Future<void> _confirmEdit(ChatMessage message) async {
    final newText = _editController.text.trim();
    if (newText.isEmpty) return;
    try {
      await ApiService().editMessage(
        widget.conversationId,
        message.id,
        newText,
      );
      final idx = _messages.indexWhere((m) => m.id == message.id);
      if (idx != -1 && mounted) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(
            text: newText,
            isEdited: true,
          );
          _editingMessageId = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to edit: $e')));
      setState(() => _editingMessageId = '');
    }
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().deleteMessage(widget.conversationId, message.id);
      final idx = _messages.indexWhere((m) => m.id == message.id);
      if (idx != -1 && mounted) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(
            isDeleted: true,
            text: ChatMessage.deletedPlaceholder,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  // ── Scroll helpers ────────────────────────────────────────────────────────

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _msgUpdateSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _presenceSub?.cancel();
    _typingTimer?.cancel();
    for (final t in _typingAutoHideTimers.values) {
      t.cancel();
    }
    if (widget.conversationId.isNotEmpty) {
      SocketService().leaveConversation(widget.conversationId);
    }
    _messageController.dispose();
    _editController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.07,
      ),
      theme.colorScheme.surface,
    );
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: GestureDetector(
          onTap: _openConversationInfo,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.threadName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_otherUserOnline)
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (_otherUserOnline)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: theme.colorScheme.onSurface),
            onPressed: _openConversationInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessagesList()),
              if (_typingUsers.values.any((v) => v)) _buildTypingIndicator(),
              if (_blockedNotice != null) _buildBlockedBanner(),
              _buildInputBar(),
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
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'New messages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Future<void> _openConversationInfo() async {
    if (widget.conversationId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationInfoScreen(
          conversationId: widget.conversationId,
          conversationTitle: widget.threadName,
        ),
      ),
    );
    if (!mounted) return;
    await _loadPresence();
    if (_blockedNotice == null && mounted) {
      setState(() {});
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _AnimatedDots(),
          const SizedBox(width: 8),
          Text(
            'typing...',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _blockedNotice ?? 'This conversation is blocked',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _openConversationInfo,
            child: const Text('Check'),
          ),
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
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
            Text(
              'No messages yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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

    final currentUserId = AuthService().currentUser?.id ?? '';
    final seenMessageIds = <String>{};
    final grouped = <String, List<ChatMessage>>{};
    for (final msg in _messages) {
      grouped.putIfAbsent(_dateLabel(msg.createdAt), () => []).add(msg);
    }

    final widgets = <Widget>[];
    if (_loadingMore) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    for (final entry in grouped.entries) {
      widgets.add(_buildDateDivider(entry.key));
      for (final msg in entry.value) {
        GlobalKey? bubbleKey;
        if (msg.id.isNotEmpty && seenMessageIds.add(msg.id)) {
          // Key used for scroll-to-message only for unique ids in current build.
          bubbleKey = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
        }
        widgets.add(_buildMessageBubble(msg, currentUserId, bubbleKey));
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: widgets,
    );
  }

  String _dateLabel(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(d.year, d.month, d.day)).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return 'Today';
    }
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildDateDivider(String date) {
    final theme = Theme.of(context);
    final divColor = theme.brightness == Brightness.dark
        ? const Color(0xFF2C2C3E)
        : const Color(0xFFEEEEF4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: divColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: divColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: divColor)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    String currentUserId,
    GlobalKey? bubbleKey,
  ) {
    final isMe = message.senderId == currentUserId;
    final isEditing = _editingMessageId == message.id;
    final theme = Theme.of(context);

    return KeyedSubtree(
      key: bubbleKey,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(message),
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 0 && !message.isDeleted) {
            setState(() => _replyTo = message);
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 8,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName : 'User',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Reply-to quoted block — tap to scroll to original
              if (message.replyToId != null && message.replyTo != null)
                GestureDetector(
                  onTap: () => _scrollToMessage(message.replyToId!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyTo!['senderName'] as String? ?? 'User',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          message.replyTo!['text'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              // Bubble or edit field
              if (isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _editController,
                        autofocus: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () => _confirmEdit(message),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _editingMessageId = ''),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isDeleted
                        ? theme.colorScheme.surfaceContainerLow
                        : isMe
                        ? AppColors.primary
                        : theme.brightness == Brightness.dark
                        ? const Color(0xFF2C2C3E)
                        : const Color(0xFFEEEEF4),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.mediaFileId != null &&
                          message.mediaType == 'image')
                        GestureDetector(
                          onTap: () => _openImageFullScreen(message),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiConstants.fileBaseUrl}/api/files/${message.mediaFileId!}/download',
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 200,
                                height: 100,
                                color: theme.colorScheme.surfaceContainerLow,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      if (message.mediaFileId != null &&
                          message.mediaType != null &&
                          message.mediaType != 'image')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: isMe
                                  ? Colors.white70
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.mediaName ?? 'File',
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: message.isDeleted
                                ? theme.colorScheme.onSurfaceVariant
                                : isMe
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              // Reactions
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: message.reactions.map((r) {
                      final isOwn = r.userIds.contains(currentUserId);
                      return GestureDetector(
                        onTap: () => _toggleReaction(message, r.emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOwn
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOwn
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '${r.emoji} ${r.userIds.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Time + edited + read ticks (for sent messages)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (message.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(edited)',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _readByMap[message.id] == true
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: _readByMap[message.id] == true
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _openImageFullScreen(ChatMessage message) {
    if (message.mediaFileId == null) return;
    final url =
        '${ApiConstants.fileBaseUrl}/api/files/${message.mediaFileId!}/download';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);
    final inputBg = theme.brightness == Brightness.dark
        ? const Color(0xFF2C2C3E)
        : const Color(0xFFEEEEF4);
    final isBlocked = _blockedNotice != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (_replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyTo!.senderName.isNotEmpty
                              ? _replyTo!.senderName
                              : 'User',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _replyTo!.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _replyTo = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Upload progress
          if (_uploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                backgroundColor: inputBg,
                color: AppColors.primary,
              ),
            ),
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _uploading ? null : _showAttachmentSheet,
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: isBlocked
                          ? 'Conversation blocked'
                          : 'Message...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                    ),
                    enabled: !isBlocked,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14.5),
                    onChanged: isBlocked ? null : _handleTyping,
                    onSubmitted: isBlocked ? null : (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending || isBlocked ? null : () => _sendMessage(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (_sending || isBlocked)
                        ? theme.colorScheme.surfaceContainerHigh
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Icon(
                          isBlocked ? Icons.block_outlined : Icons.send_rounded,
                          color: isBlocked
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo/Video from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia('gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia('file');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Animated typing dots ──────────────────────────────────────────────────────

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((_ctrl.value * 3 - i).clamp(0.0, 1.0));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
