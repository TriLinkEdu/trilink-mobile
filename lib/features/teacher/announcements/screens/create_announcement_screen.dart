import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateAnnouncementScreen({super.key, this.existing});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  // Step 1 — who: 'students' | 'parents' | 'both'
  String _recipientGroup = 'students';

  // Step 2 — class selection (only when students or both)
  // Empty set means nothing loaded yet; after load, all are selected by default.
  // _allSelected = true means "All Classes" (broad audience)
  // _allSelected = false + specific IDs = per-class announcements
  List<Map<String, dynamic>> _classOfferings = [];
  Set<String> _selectedClassIds = {};
  bool _allSelected = true; // starts as "All"
  String _gradeFilter = ''; // '' = no filter
  bool _loadingClasses = false;

  /// Classes visible after grade filter
  List<Map<String, dynamic>> get _visibleClasses {
    if (_gradeFilter.isEmpty) return _classOfferings;
    return _classOfferings.where((c) {
      final grade = (c['gradeName'] as String? ?? '').toLowerCase();
      return grade.contains(_gradeFilter.toLowerCase());
    }).toList();
  }

  /// Unique grade names from all offerings
  List<String> get _gradeNames {
    final grades = <String>{};
    for (final c in _classOfferings) {
      final g = c['gradeName'] as String? ?? '';
      if (g.isNotEmpty) grades.add(g);
    }
    final list = grades.toList()..sort();
    return list;
  }

  bool _scheduleForLater = false;
  DateTime? _scheduledDateTime;

  bool get _isEdit => widget.existing != null;
  String get _existingId => widget.existing?['id'] as String? ?? '';
  bool get _showClassStep =>
      _recipientGroup == 'students' || _recipientGroup == 'both';

  /// True when "All" is effectively selected (no specific classes chosen)
  bool get _isAllClasses => _selectedClassIds.isEmpty;

  /// Backend audience for a single-class call
  String get _singleAudience => 'class';

  /// Backend audience when targeting all (no specific class)
  String get _broadAudience {
    if (_recipientGroup == 'both') return 'all';
    if (_recipientGroup == 'parents') return 'parents';
    return 'students';
  }

  void _initFromExisting(Map<String, dynamic> e) {
    _titleController.text = e['title'] as String? ?? '';
    _bodyController.text = e['body'] as String? ?? '';
    final audience = e['audience'] as String? ?? 'students';
    switch (audience) {
      case 'all':
        _recipientGroup = 'both';
        _allSelected = true;
        _selectedClassIds = {};
        break;
      case 'students':
        _recipientGroup = 'students';
        _allSelected = true;
        _selectedClassIds = {};
        break;
      case 'parents':
        _recipientGroup = 'parents';
        _allSelected = true;
        _selectedClassIds = {};
        break;
      case 'class':
        _recipientGroup = 'both';
        _allSelected = false;
        final cid = e['classOfferingId'] as String?;
        _selectedClassIds = cid != null ? {cid} : {};
        break;
      default:
        _recipientGroup = 'students';
        _allSelected = true;
        _selectedClassIds = {};
    }
    final paStr = e['publishAt'] as String?;
    if (paStr != null && paStr.isNotEmpty) {
      final pa = DateTime.tryParse(paStr)?.toLocal();
      if (pa != null && pa.isAfter(DateTime.now())) {
        _scheduleForLater = true;
        _scheduledDateTime = pa;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) _initFromExisting(widget.existing!);
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final yearData = await ApiService().getActiveAcademicYear();
      final yearId =
          (yearData['id'] ?? yearData['data']?['id']) as String? ?? '';
      if (yearId.isNotEmpty) {
        final offerings = await ApiService().getMyClassOfferings(yearId);
        setState(() {
          _classOfferings = offerings.cast<Map<String, dynamic>>();
          // Default: all selected (but _allSelected = true means broad audience)
          _selectedClassIds = _classOfferings
              .map((c) => c['id'] as String? ?? '')
              .toSet();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      _snack('Please enter a title');
      return;
    }
    if (body.isEmpty) {
      _snack('Please enter a message');
      return;
    }
    if (_scheduleForLater && _scheduledDateTime == null) {
      _snack('Please pick a schedule date/time');
      return;
    }

    setState(() => _submitting = true);
    try {
      final yearData = await ApiService().getActiveAcademicYear();
      final yearId =
          (yearData['id'] ?? yearData['data']?['id']) as String? ?? '';
      if (!_isEdit && yearId.isEmpty) {
        throw Exception('No active academic year found');
      }

      final schedulePayload = _scheduleForLater && _scheduledDateTime != null
          ? {'publishAt': _scheduledDateTime!.toUtc().toIso8601String()}
          : <String, dynamic>{};

      if (_isEdit) {
        final audience =
            _showClassStep && !_allSelected && _selectedClassIds.isNotEmpty
            ? _singleAudience
            : _broadAudience;
        final classId =
            _showClassStep && !_allSelected && _selectedClassIds.isNotEmpty
            ? _selectedClassIds.first
            : null;
        await ApiService().updateAnnouncement(_existingId, {
          'title': title,
          'body': body,
          'audience': audience,
          if (classId != null) 'classOfferingId': classId,
          ...schedulePayload,
        });
      } else if (_showClassStep &&
          !_allSelected &&
          _selectedClassIds.isNotEmpty) {
        // Create one announcement per selected class
        for (final classId in _selectedClassIds) {
          await ApiService().createAnnouncement({
            'academicYearId': yearId,
            'title': title,
            'body': body,
            'audience': _singleAudience,
            'classOfferingId': classId,
            ...schedulePayload,
          });
        }
      } else {
        // Broad announcement
        await ApiService().createAnnouncement({
          'academicYearId': yearId,
          'title': title,
          'body': body,
          'audience': _broadAudience,
          ...schedulePayload,
        });
      }

      if (!mounted) return;
      final classCount = _selectedClassIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Announcement updated'
                : _scheduleForLater
                ? 'Scheduled for ${DateFormat('MMM d, h:mm a').format(_scheduledDateTime!)}'
                : (!_allSelected && classCount > 1)
                ? 'Sent to $classCount classes'
                : 'Announcement sent!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _classLabel(Map<String, dynamic> c) {
    final displayName = c['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final grade = c['gradeName'] as String? ?? '';
    final section = c['sectionName'] as String? ?? '';
    final subject = c['subjectName'] as String? ?? '';
    final classPart = [grade, section].where((s) => s.isNotEmpty).join(' ');
    if (classPart.isNotEmpty && subject.isNotEmpty)
      return '$classPart | $subject';
    if (classPart.isNotEmpty) return classPart;
    return subject.isNotEmpty ? subject : 'Unnamed Class';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Announcement' : 'New Announcement',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEdit
                          ? 'Save'
                          : _scheduleForLater
                          ? 'Schedule'
                          : 'Send',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: 'Announcement title...',
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outlineVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),

            // ── Body ──
            TextField(
              controller: _bodyController,
              maxLines: null,
              minLines: 5,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_bodyController.text.length} / 1000',
                style: TextStyle(
                  fontSize: 12,
                  color: _bodyController.text.length > 900
                      ? AppColors.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Step 1: Recipients ──
            const _SectionLabel(label: 'SEND TO'),
            const SizedBox(height: 12),
            _buildRecipientRow(),
            const SizedBox(height: 20),

            // ── Step 2: Class checklist ──
            if (_showClassStep) ...[
              const _SectionLabel(label: 'WHICH CLASSES'),
              const SizedBox(height: 10),
              _buildClassChecklist(),
              const SizedBox(height: 20),
            ],

            // ── Audience summary ──
            _buildAudienceSummary(),
            const SizedBox(height: 28),

            // ── Delivery ──
            const _SectionLabel(label: 'DELIVERY'),
            const SizedBox(height: 12),
            _buildDeliveryToggle(),
            if (_scheduleForLater) ...[
              const SizedBox(height: 12),
              _buildDateTimePicker(theme),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildRecipientRow() {
    final theme = Theme.of(context);
    final options = [
      ('students', 'Students', Icons.school_outlined),
      ('parents', 'Parents', Icons.family_restroom_outlined),
      ('both', 'Both', Icons.groups_outlined),
    ];
    return Row(
      children: options.map((opt) {
        final value = opt.$1;
        final label = opt.$2;
        final icon = opt.$3;
        final selected = _recipientGroup == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: value == 'both' ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _recipientGroup = value;
                // Reset class selection when switching to parents-only
                if (value == 'parents') _selectedClassIds = {};
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClassChecklist() {
    final theme = Theme.of(context);
    if (_loadingClasses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_classOfferings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          'No classes found for the current academic year.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    final grades = _gradeNames;
    final visible = _visibleClasses;
    final allVisibleSelected = visible.every(
      (c) => _selectedClassIds.contains(c['id'] as String? ?? ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Grade filter chips ──
        if (grades.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _GradeChip(
                  label: 'All Grades',
                  selected: _gradeFilter.isEmpty,
                  onTap: () => setState(() => _gradeFilter = ''),
                ),
                ...grades.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _GradeChip(
                      label: g,
                      selected: _gradeFilter == g,
                      onTap: () => setState(() => _gradeFilter = g),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Checklist ──
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              // "All" toggle — selects/deselects all visible classes
              _ChecklistTile(
                label: _gradeFilter.isEmpty
                    ? 'All Classes'
                    : 'All in $_gradeFilter',
                subtitle: _gradeFilter.isEmpty
                    ? 'Send to all your classes'
                    : 'Select all ${_gradeFilter} classes',
                icon: Icons.public,
                checked: _allSelected || allVisibleSelected,
                onTap: () => setState(() {
                  if (_allSelected || allVisibleSelected) {
                    // Deselect all visible
                    for (final c in visible) {
                      _selectedClassIds.remove(c['id'] as String? ?? '');
                    }
                    if (_gradeFilter.isEmpty) _allSelected = false;
                  } else {
                    // Select all visible
                    for (final c in visible) {
                      _selectedClassIds.add(c['id'] as String? ?? '');
                    }
                    // If all classes are now selected, mark as allSelected
                    if (_selectedClassIds.length == _classOfferings.length) {
                      _allSelected = true;
                    }
                  }
                }),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              // Individual classes
              ...visible.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final id = c['id'] as String? ?? '';
                final isLast = idx == visible.length - 1;
                return Column(
                  children: [
                    _ChecklistTile(
                      label: _classLabel(c),
                      icon: Icons.class_outlined,
                      checked: _allSelected || _selectedClassIds.contains(id),
                      onTap: () => setState(() {
                        if (_allSelected) {
                          // Expand from "all" to individual selection
                          _allSelected = false;
                          _selectedClassIds = _classOfferings
                              .map((c) => c['id'] as String? ?? '')
                              .toSet();
                        }
                        if (_selectedClassIds.contains(id)) {
                          _selectedClassIds.remove(id);
                        } else {
                          _selectedClassIds.add(id);
                          // If all are now selected, switch back to allSelected
                          if (_selectedClassIds.length ==
                              _classOfferings.length) {
                            _allSelected = true;
                            _selectedClassIds = {};
                          }
                        }
                      }),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: theme.colorScheme.surfaceContainerLowest,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceSummary() {
    String label;
    IconData icon;

    if (_recipientGroup == 'parents') {
      label = 'All parents';
      icon = Icons.family_restroom_outlined;
    } else if (_allSelected) {
      label = _recipientGroup == 'both'
          ? 'All students & parents'
          : 'All students';
      icon = Icons.groups_outlined;
    } else {
      final count = _selectedClassIds.length;
      if (count == 0) {
        label = 'No classes selected — please select at least one';
        icon = Icons.warning_amber_outlined;
      } else {
        label = _recipientGroup == 'both'
            ? 'Students & parents of $count class${count > 1 ? 'es' : ''}'
            : 'Students of $count class${count > 1 ? 'es' : ''}';
        icon = Icons.class_outlined;
        if (count > 1) {
          label += ' ($count announcements will be created)';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Will reach: $label',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryToggle() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Send Now
        InkWell(
          onTap: () => setState(() {
            _scheduleForLater = false;
            _scheduledDateTime = null;
          }),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: !_scheduleForLater
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !_scheduleForLater
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
                width: !_scheduleForLater ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _scheduleForLater,
                  onChanged: (v) => setState(() {
                    _scheduleForLater = false;
                    _scheduledDateTime = null;
                  }),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: !_scheduleForLater
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !_scheduleForLater
                              ? AppColors.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Deliver immediately to recipients',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Schedule
        InkWell(
          onTap: () => setState(() => _scheduleForLater = true),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _scheduleForLater
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _scheduleForLater
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
                width: _scheduleForLater ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _scheduleForLater,
                  onChanged: (v) => setState(() => _scheduleForLater = true),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: _scheduleForLater
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule for Later',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _scheduleForLater
                              ? AppColors.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Pick a date & time to send',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildDateTimePicker(ThemeData theme) {
    return GestureDetector(
      onTap: _pickScheduleDateTime,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _scheduledDateTime != null
                ? AppColors.primary.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: _scheduledDateTime != null
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _scheduledDateTime != null
                    ? DateFormat(
                        'EEE, MMM d, yyyy  •  h:mm a',
                      ).format(_scheduledDateTime!)
                    : 'Tap to pick date & time',
                style: TextStyle(
                  fontSize: 14,
                  color: _scheduledDateTime != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: _scheduledDateTime != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _ChecklistTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;

  const _ChecklistTile({
    required this.label,
    required this.icon,
    required this.checked,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: checked
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                      color: checked
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GradeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}
