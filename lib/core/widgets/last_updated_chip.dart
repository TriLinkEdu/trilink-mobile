import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Small, unobtrusive chip showing when data on the current page was last
/// refreshed from the network. Pair this with the SWR pattern in cubits to
/// close the trust gap created by silent background refreshes.
///
/// Pass `null` for [timestamp] to render nothing.
class LastUpdatedChip extends StatefulWidget {
  final DateTime? timestamp;
  final EdgeInsetsGeometry padding;

  const LastUpdatedChip({
    super.key,
    required this.timestamp,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  State<LastUpdatedChip> createState() => _LastUpdatedChipState();
}

class _LastUpdatedChipState extends State<LastUpdatedChip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render once a minute so the relative label stays accurate.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _relative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.timestamp;
    if (ts == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
              borderRadius: AppRadius.borderSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_relative(ts)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
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
