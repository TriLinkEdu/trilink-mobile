import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: isUnlocked
              ? Colors.amber
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isUnlocked ? Icons.emoji_events : Icons.lock,
            color: isUnlocked
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
