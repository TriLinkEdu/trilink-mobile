import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import 'attendance_session_detail_screen.dart';

// ─── Enums & Models ──────────────────────────────────────────────────────────

enum AttendanceStatus { present, late, absent, excused }

class _StudentAttendance {
  final String id;
  final String name;
  final String email;
  AttendanceStatus status;
  String note;

  _StudentAttendance({
    required this.id,
    required this.name,
    required this.email,
    this.status = AttendanceStatus.present,
    this.note = '',
  });
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Shared state ──
  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;
  bool _loadingClasses = true;
  String? _classError;

  // ── Today tab state ──
  List<_StudentAttendance> _students = [];
  bool _loadingSession = false;
  bool _submitting = false;
  String? _todaySessionId;
  bool _isEditMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ── History tab state ──
  List<Map<String, dynamic>> _sessions = [];
  bool _loadingHistory = false;
  DateTime? _historyDateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1 && _sessions.isEmpty) {
          _loadHistory();
        }
      }
    });
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  String _labelFor(Map<String, dynamic> offering) {
    final displayName = offering['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final gradeName = offering['gradeName'] as String? ?? '';
    final sectionName = offering['sectionName'] as String? ?? '';
    final subjectName = offering['subjectName'] as String? ?? '';
    final classPart = [
      gradeName,
      sectionName,
    ].where((s) => s.isNotEmpty).join(' ');
    if (classPart.isNotEmpty && subjectName.isNotEmpty) {
      return '$classPart | $subjectName';
    }
    if (classPart.isNotEmpty) return classPart;
    if (subjectName.isNotEmpty) return subjectName;
    return 'Unnamed Class';
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _classError = null;
    });
    try {
      final yearData = await ApiService().getActiveAcademicYear();
      final yearId =
          (yearData['id'] ?? yearData['data']?['id']) as String? ?? '';
      if (yearId.isEmpty) throw Exception('No active academic year');

      final offerings = await ApiService().getMyClassOfferings(yearId);
      if (!mounted) return;

      final classes = offerings.cast<Map<String, dynamic>>();
      setState(() {
        _classOfferings = classes;
        _loadingClasses = false;
      });

      if (classes.isNotEmpty) {
        _selectedClassId = classes.first['id'] as String? ?? '';
        await Future.wait([_loadSession(), _loadHistory()]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classError = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _onClassChanged(String? classId) async {
    if (classId == null || classId == _selectedClassId) return;
    setState(() {
      _selectedClassId = classId;
      _students = [];
      _sessions = [];
      _todaySessionId = null;
      _isEditMode = false;
      _historyDateFilter = null;
    });
    await Future.wait([_loadSession(), _loadHistory()]);
  }

  Future<void> _loadSession() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) return;
    setState(() => _loadingSession = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Load students
      final studentsResp = await ApiService().getClassStudents(
        _selectedClassId!,
      );
      final studentList = (studentsResp['students'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Check for existing session today
      final sessions = await ApiService().getAttendanceSessions(
        classOfferingId: _selectedClassId!,
      );
      final todaySession = sessions.cast<Map<String, dynamic>>().where((s) {
        final d = s['date'] as String? ?? '';
        return d.startsWith(today);
      }).firstOrNull;

      List<Map<String, dynamic>> existingMarks = [];
      String? sessionId;
      if (todaySession != null) {
        sessionId = todaySession['id'] as String?;
        if (sessionId != null) {
          final marks = await ApiService().getAttendanceMarks(sessionId);
          existingMarks = marks.cast<Map<String, dynamic>>();
        }
      }

      if (!mounted) return;

      final attendanceList = studentList.map((s) {
        final sid = s['studentId'] as String? ?? s['id'] as String? ?? '';
        final firstName = s['firstName'] as String? ?? '';
        final lastName = s['lastName'] as String? ?? '';
        final email = s['email'] as String? ?? '';
        final mark = existingMarks
            .where((m) => m['studentId'] == sid)
            .firstOrNull;
        AttendanceStatus status = AttendanceStatus.present;
        String note = '';
        if (mark != null) {
          status = _parseStatus(mark['status'] as String? ?? 'present');
          note = mark['note'] as String? ?? '';
        }
        return _StudentAttendance(
          id: sid,
          name: '$firstName $lastName'.trim(),
          email: email,
          status: status,
          note: note,
        );
      }).toList();

      setState(() {
        _students = attendanceList;
        _todaySessionId = sessionId;
        _isEditMode = false;
        _loadingSession = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSession = false);
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) return;
    setState(() => _loadingHistory = true);
    try {
      final report = await ApiService().getClassAttendanceReport(
        _selectedClassId!,
      );
      if (!mounted) return;
      final rawSessions = (report['sessions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _sessions = rawSessions;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  AttendanceStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }

  String _statusString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.excused:
        return 'excused';
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || _submitting) return;
    setState(() => _submitting = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String sessionId;

      if (_todaySessionId != null) {
        sessionId = _todaySessionId!;
      } else {
        final created = await ApiService().createAttendanceSession(
          classOfferingId: _selectedClassId!,
          date: today,
        );
        sessionId = created['id'] as String? ?? '';
      }

      final marks = _students
          .map(
            (s) => {
              'studentId': s.id,
              'status': _statusString(s.status),
              'note': s.note,
            },
          )
          .toList();

      await ApiService().saveAttendanceMarks(sessionId, marks);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _todaySessionId != null
                ? 'Attendance updated successfully'
                : 'Attendance submitted successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadSession();
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showExcusedDialog(_StudentAttendance student) async {
    final controller = TextEditingController(text: student.note);
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
      setState(() {
        student.status = AttendanceStatus.excused;
        student.note = result;
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Note: This screen is embedded in TeacherMainScreen which provides the AppBar
    // We wrap in Material to provide Material context for DropdownButton
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: OfflineBanner(
        child: _loadingClasses
            ? const Center(child: CircularProgressIndicator())
            : _classError != null
            ? _buildError(_classError!, _loadClasses)
            : _classOfferings.isEmpty
            ? _buildEmptyClasses()
            : Column(
                children: [
                  // TabBar with blue background
                  Material(
                    color: AppColors.primary,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Today', icon: Icon(Icons.today_outlined)),
                        Tab(
                          text: 'History',
                          icon: Icon(Icons.history_outlined),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildTodayTab(), _buildHistoryTab()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyClasses() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No classes assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no class offerings for the current academic year.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _classOfferings.map((c) {
            final id = c['id'] as String? ?? '';
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                _labelFor(c),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: _onClassChanged,
        ),
      ),
    );
  }

  // ─── Today Tab ────────────────────────────────────────────────────────────

  Widget _buildTodayTab() {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(today);
    final readOnly = _todaySessionId != null && !_isEditMode;
    final filtered = _searchQuery.isEmpty
        ? _students
        : _students.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q);
          }).toList();
    final presentCount = _students
        .where((s) => s.status == AttendanceStatus.present)
        .length;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadSession,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildClassDropdown()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_todaySessionId != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.secondary,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Attendance already submitted for today',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!_isEditMode)
                          TextButton(
                            onPressed: () => setState(() => _isEditMode = true),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_loadingSession)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_students.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students in this class',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search students...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerLow,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$presentCount / ${_students.length}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!readOnly)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            for (final s in _students) {
                              s.status = AttendanceStatus.present;
                              s.note = '';
                            }
                          });
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark All Present'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.secondary,
                          side: BorderSide(color: theme.colorScheme.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = filtered[index];
                      return _StudentAttendanceTile(
                        student: student,
                        readOnly: readOnly,
                        onStatusChanged: (status) async {
                          if (status == AttendanceStatus.excused) {
                            await _showExcusedDialog(student);
                          } else {
                            setState(() {
                              student.status = status;
                              student.note = '';
                            });
                          }
                        },
                      );
                    }, childCount: filtered.length),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!readOnly && _students.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _todaySessionId != null
                            ? 'Update Attendance'
                            : 'Submit Attendance',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── History Tab ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredSessions {
    if (_historyDateFilter == null) return _sessions;
    return _sessions.where((session) {
      final dateRaw = session['date'] as String? ?? '';
      try {
        final parsed = DateTime.parse(dateRaw);
        return parsed.year == _historyDateFilter!.year &&
            parsed.month == _historyDateFilter!.month &&
            parsed.day == _historyDateFilter!.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _pickHistoryDate() async {
    // Find the date range from sessions
    DateTime firstDate = DateTime(2020);
    DateTime lastDate = DateTime.now().add(const Duration(days: 1));
    if (_sessions.isNotEmpty) {
      final dates = _sessions.map((s) {
        try {
          return DateTime.parse(s['date'] as String? ?? '');
        } catch (_) {
          return DateTime.now();
        }
      }).toList()..sort();
      firstDate = dates.first;
      // lastDate should be at least today so the picker doesn't crash
      lastDate = dates.last.isAfter(DateTime.now())
          ? dates.last
          : DateTime.now().add(const Duration(days: 1));
    }

    // initialDate must be within [firstDate, lastDate]
    DateTime initialDate = _historyDateFilter ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Filter by date',
    );
    if (picked != null) {
      setState(() => _historyDateFilter = picked);
    }
  }

  Widget _buildHistoryTab() {
    final theme = Theme.of(context);
    final filtered = _filteredSessions;
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildClassDropdown()),
          // ── Date filter bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickHistoryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _historyDateFilter != null
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _historyDateFilter != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: _historyDateFilter != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _historyDateFilter != null
                                  ? DateFormat(
                                      'EEE, MMM d, yyyy',
                                    ).format(_historyDateFilter!)
                                  : 'Filter by date',
                              style: TextStyle(
                                color: _historyDateFilter != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _historyDateFilter != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_historyDateFilter != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          setState(() => _historyDateFilter = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear filter',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_historyDateFilter != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  '${filtered.length} session${filtered.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (_loadingHistory)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _historyDateFilter != null
                          ? 'No sessions on this date'
                          : 'No attendance history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _historyDateFilter != null
                          ? 'Try a different date or clear the filter.'
                          : 'Submitted sessions will appear here.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildSessionCard(filtered[index]);
                }, childCount: filtered.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final dateRaw = session['date'] as String? ?? '';
    final marks = (session['marks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateRaw);
    } catch (_) {}

    final dateLabel = parsedDate != null
        ? DateFormat('EEE, MMM d').format(parsedDate)
        : dateRaw;
    final fullDateLabel = parsedDate != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(parsedDate)
        : dateRaw;

    final presentCount = marks
        .where((m) => (m['status'] as String? ?? '') == 'present')
        .length;
    final absentCount = marks
        .where((m) => (m['status'] as String? ?? '') == 'absent')
        .length;
    final lateCount = marks
        .where((m) => (m['status'] as String? ?? '') == 'late')
        .length;
    final excusedCount = marks
        .where((m) => (m['status'] as String? ?? '') == 'excused')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceSessionDetailScreen(session: session),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_note,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullDateLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${marks.length} students',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (presentCount > 0)
                        _buildBadge(
                          '$presentCount P',
                          theme.colorScheme.secondary,
                        ),
                      if (absentCount > 0)
                        _buildBadge('$absentCount A', theme.colorScheme.error),
                      if (lateCount > 0)
                        _buildBadge('$lateCount L', theme.colorScheme.tertiary),
                      if (excusedCount > 0)
                        _buildBadge(
                          '$excusedCount E',
                          theme.colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _StudentAttendanceTile extends StatelessWidget {
  final _StudentAttendance student;
  final bool readOnly;
  final Future<void> Function(AttendanceStatus) onStatusChanged;

  const _StudentAttendanceTile({
    required this.student,
    required this.readOnly,
    required this.onStatusChanged,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(student.name),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name.isEmpty ? 'Unknown' : student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (student.email.isNotEmpty)
                        Text(
                          student.email,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (readOnly)
              _ReadOnlyStatusBadge(status: student.status, note: student.note)
            else
              Row(
                children: [
                  _StatusButton(
                    label: 'Present',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    selected: student.status == AttendanceStatus.present,
                    onTap: () => onStatusChanged(AttendanceStatus.present),
                  ),
                  const SizedBox(width: 6),
                  _StatusButton(
                    label: 'Late',
                    icon: Icons.access_time,
                    color: AppColors.accent,
                    selected: student.status == AttendanceStatus.late,
                    onTap: () => onStatusChanged(AttendanceStatus.late),
                  ),
                  const SizedBox(width: 6),
                  _StatusButton(
                    label: 'Absent',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    selected: student.status == AttendanceStatus.absent,
                    onTap: () => onStatusChanged(AttendanceStatus.absent),
                  ),
                  const SizedBox(width: 6),
                  _StatusButton(
                    label: 'Excused',
                    icon: Icons.note_outlined,
                    color: AppColors.secondary,
                    selected: student.status == AttendanceStatus.excused,
                    onTap: () => onStatusChanged(AttendanceStatus.excused),
                  ),
                ],
              ),
            if (student.status == AttendanceStatus.excused &&
                student.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        student.note,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyStatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final String note;

  const _ReadOnlyStatusBadge({required this.status, required this.note});

  Color get _color {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.accent;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.excused:
        return AppColors.secondary;
    }
  }

  String get _label {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  IconData get _icon {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
