import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/role_page_background.dart';

class TeacherAnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final bool isOwn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TeacherAnnouncementDetailScreen({
    super.key,
    required this.announcement,
    this.isOwn = false,
    this.onEdit,
    this.onDelete,
  });

  String get _title => announcement['title'] as String? ?? 'Announcement';
  String get _body =>
      announcement['body'] as String? ??
      announcement['message'] as String? ??
      '';
  String get _audience => announcement['audience'] as String? ?? 'all';
  String? get _targetGrade => announcement['targetGrade'] as String?;
  String? get _publishAtRaw => announcement['publishAt'] as String?;
  String? get _createdAtRaw => announcement['createdAt'] as String?;

  bool get _isScheduled {
    if (_publishAtRaw == null || _publishAtRaw!.isEmpty) return false;
    final dt = DateTime.tryParse(_publishAtRaw!)?.toLocal();
    return dt != null && dt.isAfter(DateTime.now());
  }

  DateTime? get _displayDate {
    if (_isScheduled && _publishAtRaw != null) {
      return DateTime.tryParse(_publishAtRaw!)?.toLocal();
    }
    if (_createdAtRaw != null) {
      return DateTime.tryParse(_createdAtRaw!)?.toLocal();
    }
    return null;
  }

  String get _audienceLabel {
    switch (_audience) {
      case 'all':
        return 'Everyone';
      case 'students':
        return 'Students';
      case 'parents':
        return 'Parents';
      case 'teachers':
        return 'Teachers';
      case 'class':
        return 'Class';
      case 'grade':
        return _targetGrade != null ? 'Grade $_targetGrade' : 'Grade';
      default:
        return _audience;
    }
  }

  IconData get _audienceIcon {
    switch (_audience) {
      case 'all':
        return Icons.public;
      case 'students':
        return Icons.school_outlined;
      case 'parents':
        return Icons.family_restroom_outlined;
      case 'teachers':
        return Icons.person_outline;
      case 'class':
        return Icons.class_outlined;
      case 'grade':
        return Icons.grade_outlined;
      default:
        return Icons.group_outlined;
    }
  }

  Color get _statusColor =>
      _isScheduled ? AppColors.accent : AppColors.success;
  String get _statusLabel => _isScheduled ? 'Scheduled' : 'Sent';
  IconData get _statusIcon =>
      _isScheduled ? Icons.schedule : Icons.check_circle_outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isOwn ? AppColors.primary : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Announcement',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isOwn && (onEdit != null || onDelete != null))
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: theme.colorScheme.onSurface),
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ]),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
              ],
              onSelected: (v) {
                Navigator.pop(context);
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
            ),
        ],
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOwn ? _audienceIcon : Icons.admin_panel_settings_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status + audience badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _Badge(
                          icon: _statusIcon,
                          label: _statusLabel,
                          color: Colors.white,
                          bgColor: Colors.white.withValues(alpha: 0.2),
                        ),
                        _Badge(
                          icon: _audienceIcon,
                          label: _audienceLabel,
                          color: Colors.white,
                          bgColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Meta info ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_displayDate != null) ...[
                      _MetaRow(
                        icon: _isScheduled
                            ? Icons.schedule
                            : Icons.access_time_outlined,
                        label: _isScheduled ? 'Scheduled for' : 'Published',
                        value: DateFormat('EEEE, MMMM d, yyyy  •  h:mm a')
                            .format(_displayDate!),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _MetaRow(
                      icon: _audienceIcon,
                      label: 'Audience',
                      value: _audienceLabel,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    if (!isOwn) ...[
                      const SizedBox(height: 12),
                      _MetaRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'From',
                        value: 'School Administration',
                        color: theme.colorScheme.primary,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 24),

                    // ── Body content ──
                    Text(
                      _body,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
