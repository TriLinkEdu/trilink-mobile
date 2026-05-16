import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/ai_chat_cubit.dart';
import '../models/ai_assistant_models.dart';

const _kMaxMessageLen = 600;
const _kCounterWarnAt = 500;

const _kStarterQuestions = [
  'Explain photosynthesis in simple terms',
  'Help me solve a quadratic equation',
  'What caused World War I?',
  "What is Newton's second law of motion?",
];

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiChatCubit>().loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {});
    await context.read<AiChatCubit>().sendMessage(text);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _fillStarter(String question) {
    _controller.text = question;
    setState(() {});
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: BlocConsumer<AiChatCubit, AiChatState>(
            listener: (context, state) => _scrollToBottom(),
            builder: (context, state) {
              if (state.isLoadingHistory) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state.messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: theme.colorScheme.primary.withAlpha(120),
                        ),
                        AppSpacing.gapLg,
                        Text(
                          'Ask me anything',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'I can help with your subjects, exam prep, and more.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _kStarterQuestions
                              .map((q) => ActionChip(
                                    label: Text(
                                      q,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    onPressed: () => _fillStarter(q),
                                    avatar: Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.messages.length + (state.isResponding ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return _TypingIndicator(
                      theme: theme,
                      stage: state.chatStage,
                    );
                  }
                  final message = state.messages[index];
                  return _ChatBubble(message: message);
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
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLength: _kMaxMessageLen,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            currentLength >= _kCounterWarnAt
                                ? Text(
                                    '$currentLength / $maxLength',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: currentLength == maxLength
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                        decoration: InputDecoration(
                          hintText: 'Ask the AI assistant...',
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
                        ),
                      );
                    },
                  ),
                ),
                AppSpacing.hGapSm,
                BlocBuilder<AiChatCubit, AiChatState>(
                  builder: (context, state) {
                    return FloatingActionButton.small(
                      tooltip: 'Send message',
                      onPressed: state.isResponding ? null : _sendMessage,
                      child: state.isResponding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isError = message.isError;

    final Color bubbleColor;
    final Color textColor;
    if (isUser) {
      bubbleColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isError) {
      bubbleColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    } else {
      bubbleColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isError
                  ? theme.colorScheme.error.withAlpha(25)
                  : theme.colorScheme.primary.withAlpha(25),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.auto_awesome,
                size: 16,
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            AppSpacing.hGapSm,
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: AppRadius.borderMd,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(color: textColor),
                  ),
                  if (!isUser &&
                      message.sources != null &&
                      message.sources!.isNotEmpty) ..._buildSources(
                    context, message.sources!, theme),
                  if (isError) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            context.read<AiChatCubit>().retryLast(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    DateFormat.jm().format(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: textColor.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSources(
    BuildContext context,
    List<AiChatSource> sources,
    ThemeData theme,
  ) {
    return [
      const SizedBox(height: 8),
      Text(
        'Sources:',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: sources
            .map(
              (s) => ActionChip(
                label: Text(
                  s.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                avatar: Icon(
                  Icons.menu_book_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                backgroundColor:
                    theme.colorScheme.primaryContainer.withAlpha(80),
                side: BorderSide.none,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.title),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    ];
  }
}

class _TypingIndicator extends StatelessWidget {
  final ThemeData theme;
  final String? stage;

  const _TypingIndicator({required this.theme, this.stage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withAlpha(25),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          AppSpacing.hGapSm,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.hGapSm,
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    stage ?? 'Thinking…',
                    key: ValueKey(stage),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
