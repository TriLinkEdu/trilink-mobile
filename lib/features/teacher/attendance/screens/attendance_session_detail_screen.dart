import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _EditableMark {
  final String studentId;
  final String firstName;
  final String lastName;
  String status;
  String note;
  bool changed;

  _EditableMark({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.note,
    this.changed = false,
  });

  String get name => '$firstName $lastName'.trim();
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AttendanceSessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const AttendanceSessionDetailScreen({super.key, required this.session});

  @override
  State<AttendanceSessionDetailScreen> createState() =>
      _AttendanceSessionDetailScreenState();
}

class _AttendanceSessionDetailScreenState
    extends State<AttendanceSessionDetailScreen> {
  String _filter = 'all';
  String _search = '';
  bool _editMode = false;
  bool _saving = false;
  final TextEditingController _searchController = TextEditingController();

  late List<_EditableMark> _marks;

  static const _statuses = ['present', 'late', 'absent', 'excused'];

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  void _loadMarks() {
    final raw = (widget.session['marks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    _marks = raw
        .map((m) => _EditableMark(
              studentId: m['studentId'] as String? ?? '',
              firstName: m['studentFirstName'] as String? ?? '',
              lastName: m['studentLastName'] as String? ?? '',
              status: (m['status'] as String? ?? 'present').toLowerCase(),
              note: m['note'] as String? ?? '',
            ))
        .toList();
  }

  String get _sessionId =>
      widget.session['sessionId'] as String? ??
      widget.session['id'] as String? ??
      '';

  String get _dateLabel {
    final dateRaw = widget.session['date'] as String? ?? '';
    try {
      return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(dateRaw));
    } catch (_) {
      return dateRaw;
    }
  }

  int _countStatus(String status) =>
      _marks.where((m) => m.status == status).length;

  bool get _hasChanges => _marks.any((m) => m.changed);

  List<_EditableMark> get _filtered {
    return _marks.where((m) {
      final matchesFilter = _filter == 'all' || m.status == _filter;
      final matchesSearch =
          _search.isEmpty || m.name.toLowerCase().contains(_search.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.accent;
      case 'excused':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_outline;
      case 'absent':
        return Icons.cancel_outlined;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.note_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _onStatusChanged(_EditableMark mark, String newStatus) async {
    setState(() {
      mark.status = newStatus;
      mark.changed = true;
      if (newStatus != 'excused') mark.note = '';
    });

    if (newStatus == 'excused') {
      await _showNoteDialog(mark);
    }
  }

  Future<void> _showNoteDialog(_EditableMark mark) async {
    final controller = TextEditingController(text: mark.note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excused Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for excused absence...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => mark.note = result);
    }
  }

  Future<void> _saveChanges() async {
    if (_sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ID not found')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Send ALL marks (bulk upsert — backend handles it)
      final payload = _marks
          .where((m) => m.studentId.isNotEmpty)
          .map((m) => {
                'studentId': m.studentId,
                'status': m.status,
                'note': m.note,
              })
          .toList();

      await ApiService().saveAttendanceMarks(_sessionId, payload);

      // Sync changes back into the session map so the list stays accurate
      final sessionMarks =
          widget.session['marks'] as List<dynamic>? ?? [];
      for (final mark in _marks) {
        final idx = sessionMarks.indexWhere(
            (m) => (m as Map<String, dynamic>)['studentId'] == mark.studentId);
        if (idx >= 0) {
          (sessionMarks[idx] as Map<String, dynamic>)['status'] = mark.status;
          (sessionMarks[idx] as Map<String, dynamic>)['note'] = mark.note;
        }
      }

      if (!mounted) return;
      // Reset changed flags
      for (final m in _marks) {
        m.changed = false;
      }
      setState(() => _editMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _cancelEdit() async {
    if (await _confirmDiscard()) {
      _loadMarks();
      setState(() => _editMode = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentCount = _countStatus('present');
    final absentCount = _countStatus('absent');
    final lateCount = _countStatus('late');
    final excusedCount = _countStatus('excused');
    final total = _marks.length;
    final filtered = _filtered;
    final changedCount = _marks.where((m) => m.changed).length;

    return PopScope(
      canPop: !_editMode || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _cancelEdit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Session Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_editMode && _hasChanges) {
                _cancelEdit();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (!_editMode)
              TextButton.icon(
                onPressed: () => setState(() => _editMode = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              )
            else ...[
              TextButton(
                onPressed: _saving ? null : _cancelEdit,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (_saving || !_hasChanges) ? null : _saveChanges,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _hasChanges ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        changedCount > 0 ? 'Save ($changedCount)' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // ── Edit mode banner ──
            if (_editMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(Icons.edit_note,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use the dropdown on each student to change their status.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Date + summary header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              color: AppColors.primary.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SummaryBadge(
                        label: 'Present',
                        count: presentCount,
                        total: total,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _SummaryBadge(
                        label: 'Absent',
                        count: absentCount,
                        total: total,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      _SummaryBadge(
                        label: 'Late',
                        count: lateCount,
                        total: total,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      _SummaryBadge(
                        label: 'Excused',
                        count: excusedCount,
                        total: total,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            // ── Status filter chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All ($total)',
                      selected: _filter == 'all',
                      color: AppColors.primary,
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Present ($presentCount)',
                      selected: _filter == 'present',
                      color: AppColors.success,
                      onTap: () => setState(() => _filter = 'present'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Absent ($absentCount)',
                      selected: _filter == 'absent',
                      color: AppColors.error,
                      onTap: () => setState(() => _filter = 'absent'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Late ($lateCount)',
                      selected: _filter == 'late',
                      color: AppColors.accent,
                      onTap: () => setState(() => _filter = 'late'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Excused ($excusedCount)',
                      selected: _filter == 'excused',
                      color: AppColors.secondary,
                      onTap: () => setState(() => _filter = 'excused'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Student list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No students match',
                            style:
                                TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final mark = filtered[i];
                        return _StudentMarkRow(
                          mark: mark,
                          editMode: _editMode,
                          statusColor: _statusColor(mark.status),
                          statusIcon: _statusIcon(mark.status),
                          onStatusChanged: (newStatus) =>
                              _onStatusChanged(mark, newStatus),
                          onEditNote: () => _showNoteDialog(mark),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student Row ──────────────────────────────────────────────────────────────

class _StudentMarkRow extends StatelessWidget {
  final _EditableMark mark;
  final bool editMode;
  final Color statusColor;
  final IconData statusIcon;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onEditNote;

  static const _statuses = ['present', 'late', 'absent', 'excused'];

  const _StudentMarkRow({
    required this.mark,
    required this.editMode,
    required this.statusColor,
    required this.statusIcon,
    required this.onStatusChanged,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mark.changed
              ? AppColors.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
          width: mark.changed ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              mark.initials,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mark.name.isEmpty ? 'Unknown' : mark.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (mark.changed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (mark.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mark.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (editMode && mark.status == 'excused')
                          GestureDetector(
                            onTap: onEditNote,
                            child: Icon(Icons.edit,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status — dropdown in edit mode, badge in view mode
          if (editMode)
            _StatusDropdown(
              value: mark.status,
              statusColor: statusColor,
              onChanged: onStatusChanged,
            )
          else
            _StatusBadge(
              status: mark.status,
              color: statusColor,
              icon: statusIcon,
            ),
        ],
      ),
    );
  }
}

// ─── Status Dropdown ──────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String value;
  final Color statusColor;
  final ValueChanged<String> onChanged;

  static const _statuses = ['present', 'late', 'absent', 'excused'];

  static Color _colorFor(String s) {
    switch (s) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.accent;
      case 'excused':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  const _StatusDropdown({
    required this.value,
    required this.statusColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: statusColor),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: _statuses
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _colorFor(s),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                            color: _colorFor(s),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─── Status Badge (view mode) ─────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Badge ────────────────────────────────────────────────────────────

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
