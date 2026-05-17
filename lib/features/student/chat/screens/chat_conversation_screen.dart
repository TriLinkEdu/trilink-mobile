import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/chat_conversation_cubit.dart';
import '../repositories/student_chat_repository.dart';
import '../widgets/chat_bubble.dart';
import '../models/chat_models.dart';
import '../widgets/chat_profile_sheet.dart';
import '../../../../core/services/chat_socket_service.dart';

class ChatConversationScreen extends StatelessWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarPath;
  final String? partnerId;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.isGroup = false,
    this.avatarPath,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => ChatConversationCubit(
        sl<StudentChatRepository>(),
        conversationId,
        socketService: sl<ChatSocketService>(),
        currentUserId: currentUserId,
      )..loadIfNeeded(),
      child: _ChatConversationView(
        conversationId: conversationId,
        title: title,
        isGroup: isGroup,
        avatarPath: avatarPath,
        partnerId: partnerId,
      ),
    );
  }
}

class _ChatConversationView extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarPath;
  final String? partnerId;

  const _ChatConversationView({
    required this.conversationId,
    required this.title,
    required this.isGroup,
    required this.avatarPath,
    this.partnerId,
  });

  @override
  State<_ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<_ChatConversationView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  // ── Draft store: static in-memory map persists across navigation ──
  static final Map<String, String> _drafts = {};

  @override
  void initState() {
    super.initState();
    // Restore saved draft for this conversation
    final draft = _drafts[widget.conversationId];
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
      _controller.selection = TextSelection.collapsed(offset: draft.length);
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    // Load more when near top (reversed list → minScrollExtent is the bottom)
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      context.read<ChatConversationCubit>().loadMoreMessages();
    }
    // Show scroll-to-bottom FAB when scrolled up more than 200px
    final shouldShow = pos.pixels < pos.maxScrollExtent - 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  @override
  void dispose() {
    // Save draft before leaving
    _drafts[widget.conversationId] = _controller.text;
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // reversed list: 0 = bottom
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _drafts[widget.conversationId] = '';
    _scrollToBottom();
    try {
      await context.read<ChatConversationCubit>().sendMessage(text);
    } catch (_) {
      // Optimistic bubble already shows failed state — no snackbar needed
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      _scrollToBottom();
      await context.read<ChatConversationCubit>().sendImageMessage(image.path);
    } catch (_) {}
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null || path.isEmpty) return;
      _scrollToBottom();
      await context.read<ChatConversationCubit>().sendFileMessage(path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send file')));
    }
  }

  void _showProfileSheet(String userId, ChatMemberModel? member) {
    if (userId.isEmpty) return;
    final currentUserId = context.read<AuthCubit>().state.user?.id ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChatProfileSheet(
        userId: userId,
        currentUserId: currentUserId,
        member: member,
        repository: sl<StudentChatRepository>(),
      ),
    );
  }

  void _openImageViewer(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            if (!widget.isGroup && widget.partnerId != null) {
              _showProfileSheet(widget.partnerId!, null);
            }
          },
          child: Row(
            children: [
              Hero(
                tag: 'chat-avatar-${widget.conversationId}',
                child: Material(
                  type: MaterialType.transparency,
                  child: ProfileAvatar(
                    radius: 18,
                    profileImagePath: widget.avatarPath,
                    fallbackText: widget.title,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(widget.title, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
      body: StudentPageBackground(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatConversationCubit, ChatConversationState>(
                builder: (context, state) {
                  final loading =
                      state.status == ConversationStatus.initial ||
                      state.status == ConversationStatus.loading;
                  if (loading) {
                    return const Padding(
                      padding: AppSpacing.paddingLg,
                      child: ShimmerList(),
                    );
                  }

                  if (state.status == ConversationStatus.error) {
                    return AppErrorWidget(
                      message: state.errorMessage ?? 'Unable to load messages.',
                      onRetry: () =>
                          context.read<ChatConversationCubit>().loadMessages(),
                    );
                  }

                  final membersById = {
                    for (final member in state.members) member.userId: member,
                  };
                  final showSenderNames =
                      widget.isGroup || state.members.length > 2;
                  final messages = state.messages;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.paddingMd,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final currentUserId =
                          context.read<AuthCubit>().state.user?.id ?? '';
                      final message = messages[index];
                      final isMine = message.senderId == currentUserId;
                      final member = membersById[message.senderId];
                      final avatarPath =
                          member?.profileImagePath ??
                          message.senderProfileImage;
                      final role = (member?.role ?? message.senderRole ?? '')
                          .toLowerCase();
                      final roleLabel = role == 'teacher'
                          ? 'Teacher'
                          : role == 'student'
                          ? 'Classmate'
                          : null;

                      return ChatBubble(
                        message: message,
                        isMe: isMine,
                        time: DateFormat.jm().format(message.timestamp),
                        showSenderName: showSenderNames,
                        senderRoleLabel: roleLabel,
                        avatarPath: avatarPath,
                        onAvatarTap: () =>
                            _showProfileSheet(message.senderId, member),
                        onImageTap:
                            message.type == MessageType.image &&
                                message.mediaUrl != null
                            ? () => _openImageViewer(message.mediaUrl!)
                            : null,
                        onAttachmentTap:
                            message.type == MessageType.file &&
                                message.mediaUrl != null
                            ? () => _openAttachment(message.mediaUrl!)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickAndSendFile,
                      tooltip: 'Send file',
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      onPressed: _pickAndSendImage,
                      tooltip: 'Send image',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 800,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderXxl,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    FloatingActionButton.small(
                      tooltip: 'Send message',
                      onPressed: _sendMessage,
                      child: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
