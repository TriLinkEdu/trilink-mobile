import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/chat_conversation_cubit.dart';
import '../repositories/student_chat_repository.dart';
import '../widgets/chat_bubble.dart';

class ChatConversationScreen extends StatelessWidget {
  final String conversationId;
  final String title;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatConversationCubit(
        sl<StudentChatRepository>(),
        conversationId,
      )..loadMessages(),
      child: _ChatConversationView(
        conversationId: conversationId,
        title: title,
      ),
    );
  }
}

class _ChatConversationView extends StatefulWidget {
  final String conversationId;
  final String title;

  const _ChatConversationView({
    required this.conversationId,
    required this.title,
  });

  @override
  State<_ChatConversationView> createState() =>
      _ChatConversationViewState();
}

class _ChatConversationViewState extends State<_ChatConversationView> {
  static const String _currentUserId = 'student1';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  Timer? _autoReplyTimer;

  @override
  void dispose() {
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
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
                child: CircleAvatar(
                  radius: 18,
                  child: Text(
                    widget.title.characters.first.toUpperCase(),
                  ),
                ),
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatConversationCubit, ChatConversationState>(
              builder: (context, state) {
                final loading = state.status == ConversationStatus.initial ||
                    state.status == ConversationStatus.loading;
                if (loading) {
                  return const Padding(
                    padding: AppSpacing.paddingLg,
                    child: ShimmerList(),
                  );
                }

                final messages = state.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: AppSpacing.paddingMd,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _currentUserId;
                    return ChatBubble(
                      message: message.content,
                      isMe: isMine,
                      time: DateFormat.jm().format(message.timestamp),
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
    );
  }
}
