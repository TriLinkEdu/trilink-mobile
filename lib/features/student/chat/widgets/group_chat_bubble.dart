import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';

class GroupChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final String? imageUrl;
  final String senderId;
  final String senderName;
  final String? senderProfileImage;
  final String? senderRole;
  final String? senderGrade;
  final VoidCallback? onTapProfile;

  const GroupChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    this.imageUrl,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    this.senderRole,
    this.senderGrade,
    this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: onTapProfile,
              child: _buildAvatar(theme),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  GestureDetector(
                    onTap: onTapProfile,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            senderName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (senderRole != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(theme),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getRoleLabel(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl!,
                            height: 160,
                            width: 220,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                height: 160,
                                width: 220,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              height: 160,
                              width: 220,
                              child: Text(
                                'Unable to load image',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (message.isNotEmpty) ...[
                        if (imageUrl != null) const SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(
                            color: isMe
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? theme.colorScheme.onPrimaryContainer.withAlpha(179)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (senderProfileImage != null && senderProfileImage!.isNotEmpty) {
      final imageUrl = senderProfileImage!.startsWith('http')
          ? senderProfileImage!
          : '${ApiConstants.baseUrl}$senderProfileImage';
      
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      );
    }

    // Generate avatar from initials
    final initials = _getInitials(senderName);
    final color = _getColorFromString(senderId);

    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getColorFromString(String str) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final hash = str.hashCode.abs();
    return colors[hash % colors.length];
  }

  Color _getRoleColor(ThemeData theme) {
    if (senderRole == 'teacher') return Colors.orange;
    if (senderRole == 'student') return theme.colorScheme.primary;
    return Colors.grey;
  }

  String _getRoleLabel() {
    if (senderRole == 'teacher') return 'TEACHER';
    if (senderRole == 'student') return 'STUDENT';
    return senderRole?.toUpperCase() ?? '';
  }
}
