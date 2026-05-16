import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';

class ConnectionRequestDialog extends StatelessWidget {
  final ChatContactModel contact;
  final StudentChatRepository repository;

  const ConnectionRequestDialog({
    super.key,
    required this.contact,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      title: Text('Send Connection Request?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send a connection request to ${contact.fullName}?',
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.gapSm,
          Text(
            'You\'ll be able to message each other once they accept.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await repository.requestConnection(contact.id);
              if (context.mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connection request sent!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send request')),
                );
              }
            }
          },
          child: Text('Send Request'),
        ),
      ],
    );
  }
}
