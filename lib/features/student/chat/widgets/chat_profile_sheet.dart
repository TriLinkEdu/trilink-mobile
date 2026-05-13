import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';

class ChatProfileSheet extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final ChatMemberModel? member;
  final StudentChatRepository repository;

  const ChatProfileSheet({
    super.key,
          _buildStatusRow(
            'Request sent',
            Icons.access_time,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: profile.connectionId == null || _working
                ? null
                : () => _runAction(
                      () => widget.repository
                          .cancelConnection(profile.connectionId!),
                      successMessage: 'Request canceled',
                    ),
            child: const Text('Cancel request'),
          ),
        ],
      );
    }

    if (status == 'pending_received') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: profile.connectionId == null || _working
                  ? null
                  : () => _runAction(
                        () => widget.repository
                            .acceptConnection(profile.connectionId!),
                        successMessage: 'Connection accepted',
                      ),
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: profile.connectionId == null || _working
                  ? null
                  : () => _runAction(
                        () => widget.repository
                            .rejectConnection(profile.connectionId!),
                        successMessage: 'Request declined',
                      ),
              child: const Text('Decline'),
            ),
          ),
        ],
      );
    try {
      await action();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _working
            ? null
            : () => _runAction(
                  () => widget.repository.requestConnection(widget.userId),
                  successMessage: 'Connection request sent',
                ),
        icon: const Icon(Icons.person_add),
        label: const Text('Send connection request'),
      ),
    );
  }

  Widget _buildBlockAction(bool isBlocked) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _working
            ? null
            : () => _runAction(
                  () => isBlocked
                      ? widget.repository.unblockUser(widget.userId)
                      : widget.repository.blockUser(widget.userId),
                  successMessage: isBlocked ? 'User unblocked' : 'User blocked',
                ),
        icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
        label: Text(isBlocked ? 'Unblock user' : 'Block user'),
      ),
    );
  }

  Widget _buildStatusRow(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  Row(
                    children: [
                      ProfileAvatar(
                        radius: 28,
                        profileImagePath: profile?.profileImagePath ??
                            widget.member?.profileImagePath,
                        fallbackText: displayName,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (roleLabel != null)
                              Text(
                                roleLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (profile != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (profile.grade != null && profile.grade!.isNotEmpty)
                          _buildPill(theme, 'Grade ${profile.grade!}'),
                        if (profile.section != null &&
                            profile.section!.isNotEmpty)
                          _buildPill(theme, 'Section ${profile.section!}'),
                        if (profile.subject != null &&
                            profile.subject!.isNotEmpty)
                          _buildPill(theme, profile.subject!),
                        if (profile.department != null &&
                            profile.department!.isNotEmpty)
                          _buildPill(theme, profile.department!),
                        if (profile.role == 'student')
                          _buildPill(theme, '${profile.totalXp} XP'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!isSelf) _buildConnectionActions(profile),
                    if (!isSelf) const SizedBox(height: 12),
                    if (!isSelf)
                      _buildBlockAction(profile.isBlocked),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildPill(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium,
      ),
    );
  }

  Widget _buildConnectionActions(ChatInteractionProfile profile) {
    final status = profile.connectionStatus;

    if (status == 'accepted') {
      return _buildStatusRow('Connected', Icons.check_circle, Colors.green);
    }

    if (status == 'pending_sent') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusRow(
            'Request sent',
            Icons.access_time,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: profile.connectionId == null || _working
                ? null
                : () => _runAction(
                      () => widget.repository
                          .cancelConnection(profile.connectionId!),
                      successMessage: 'Request canceled',
                    ),
            child: const Text('Cancel request'),
          ),
        ],
      );
    }

    if (status == 'pending_received') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: profile.connectionId == null || _working
                  ? null
                  : () => _runAction(
                        () => widget.repository
                            .acceptConnection(profile.connectionId!),
                        successMessage: 'Connection accepted',
                      ),
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: profile.connectionId == null || _working
                  ? null
                  : () => _runAction(
                        () => widget.repository
                            .rejectConnection(profile.connectionId!),
                        successMessage: 'Request declined',
                      ),
              child: const Text('Decline'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _working
            ? null
            : () => _runAction(
                  () => widget.repository.requestConnection(widget.userId),
                  successMessage: 'Connection request sent',
                ),
        icon: const Icon(Icons.person_add),
        label: const Text('Send connection request'),
      ),
    );
  }

  Widget _buildBlockAction(bool isBlocked) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _working
            ? null
            : () => _runAction(
                  () => isBlocked
                      ? widget.repository.unblockUser(widget.userId)
                      : widget.repository.blockUser(widget.userId),
                  successMessage: isBlocked ? 'User unblocked' : 'User blocked',
                ),
        icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
        label: Text(isBlocked ? 'Unblock user' : 'Block user'),
      ),
    );
  }

  Widget _buildStatusRow(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
