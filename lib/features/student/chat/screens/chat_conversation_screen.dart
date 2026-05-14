import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
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

class ChatConversationScreen extends StatelessWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarPath;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.isGroup = false,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChatConversationCubit(sl<StudentChatRepository>(), conversationId)
            ..loadIfNeeded(),
      child: _ChatConversationView(
        conversationId: conversationId,
        title: title,
        isGroup: isGroup,
        avatarPath: avatarPath,
      ),
    );
  }
}

class _ChatConversationView extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarPath;

  const _ChatConversationView({
    required this.conversationId,
    required this.title,
    required this.isGroup,
    required this.avatarPath,
  });

  @override
  State<_ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<_ChatConversationView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  Timer? _autoReplyTimer;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50) {
      context.read<ChatConversationCubit>().loadMoreMessages();
    }
  }

  Future<void> _loadCurrentUserId() async {
    final user = await sl<StorageService>().getUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = (user?['id'] ?? '').toString();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    _autoReplyTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await context.read<ChatConversationCubit>().sendMessage(text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _isSending = false);
      _scrollToBottom();

      _autoReplyTimer?.cancel();
      final cubit = context.read<ChatConversationCubit>();
      _autoReplyTimer = Timer(const Duration(milliseconds: 1200), () async {
        if (!mounted) return;
        await cubit.loadMessages(showLoading: false);
        if (!mounted) return;
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      setState(() => _isSending = true);

      await context.read<ChatConversationCubit>().sendImageMessage(image.path);
      
      if (!mounted) return;
      setState(() => _isSending = false);
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_isSending) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null || path.isEmpty) return;

      setState(() => _isSending = true);
      await context.read<ChatConversationCubit>().sendFileMessage(path);

      if (!mounted) return;
      setState(() => _isSending = false);
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send file')),
      );
    }
  }

  void _showProfileSheet(String userId, ChatMemberModel? member) {
    if (userId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChatProfileSheet(
        userId: userId,
        currentUserId: _currentUserId,
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
        title: Row(
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
                      final message = messages[index];
                      final isMine = message.senderId == _currentUserId;
                      final member = membersById[message.senderId];
                      final avatarPath = member?.profileImagePath ??
                          message.senderProfileImage;
                      final role =
                          (member?.role ?? message.senderRole ?? '').toLowerCase();
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
                        onImageTap: message.type == MessageType.image &&
                                message.mediaUrl != null
                            ? () => _openImageViewer(message.mediaUrl!)
                            : null,
                        onAttachmentTap: message.type == MessageType.file &&
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
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
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
