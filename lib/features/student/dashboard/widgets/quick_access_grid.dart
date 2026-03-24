import 'package:flutter/material.dart';

class QuickAccessGrid extends StatelessWidget {
  final void Function(String key)? onTapItem;

  const QuickAccessGrid({super.key, this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAccessChip(
              icon: Icons.grade_rounded,
              label: 'Grades',
              onTap: () => onTapItem?.call('grades'),
            ),
            _QuickAccessChip(
              icon: Icons.campaign_rounded,
              label: 'Announcements',
              onTap: () => onTapItem?.call('announcements'),
            ),
            _QuickAccessChip(
              icon: Icons.auto_awesome_rounded,
              label: 'AI Assistant',
              onTap: () => onTapItem?.call('ai_assistant'),
            ),
            _QuickAccessChip(
              icon: Icons.event_rounded,
              label: 'Calendar',
              onTap: () => onTapItem?.call('calendar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
