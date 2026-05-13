import 'package:flutter/material.dart';

import '../../shared/widgets/profile_avatar.dart';
import '../models/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String time;
  final bool showSenderName;
  final String? senderRoleLabel;
  final String? avatarPath;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onAttachmentTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    required this.showSenderName,
    this.senderRoleLabel,
    this.avatarPath,
    this.onAvatarTap,
    this.onImageTap,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final avatar = GestureDetector(
      onTap: onAvatarTap,
      child: ProfileAvatar(
        radius: 18,
        userId: isMe ? 'current' : null,
        profileImagePath: isMe ? null : avatarPath,
        fallbackText: message.senderName,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) avatar,
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.senderName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (senderRoleLabel != null &&
                          senderRoleLabel!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            senderRoleLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                if (showSenderName && !isMe) const SizedBox(height: 4),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (message.type == MessageType.image &&
                          message.mediaUrl != null) ...[
                        GestureDetector(
                          onTap: onImageTap,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.mediaUrl!,
                              height: 170,
                              width: 230,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                height: 170,
                                width: 230,
                                child: Text(
                                  'Unable to load image',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (message.type == MessageType.file &&
                          message.mediaUrl != null) ...[
                        GestureDetector(
                          onTap: onAttachmentTap,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.mediaName ?? 'Attachment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      if (message.mediaSize != null)
                                        Text(
                                          _formatBytes(message.mediaSize!),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color:
                                                theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (message.content.isNotEmpty) ...[
                        if (message.type != MessageType.text)
                          const SizedBox(height: 8),
                        Text(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? theme.colorScheme.onPrimaryContainer
                                  .withAlpha(179)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) avatar,
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}
