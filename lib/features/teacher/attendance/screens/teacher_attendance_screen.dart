import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/api_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  bool _loadingClasses = true;
  bool _loadingSession = false;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;

  final String _date = DateFormat('MMM d, yyyy').format(DateTime.now());
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<_StudentAttendance> _students = [];

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final v = value.toString().trim();
    return v.isEmpty ? null : v;
  }

  String? _extractAcademicYearId(Map<String, dynamic> data) {
    // Check direct id
    final direct = _stringValue(data['id']);
    if (direct != null) return direct;

    // Check data.id (backend response format)
    final dataField = data['data'];
    if (dataField is Map<String, dynamic>) {
      final dataId = _stringValue(dataField['id']);
      if (dataId != null) return dataId;
    }

    // Check nested academicYear.id
    final nestedYear = data['academicYear'];
    if (nestedYear is Map<String, dynamic>) {
      return _stringValue(nestedYear['id']);
    }
    return null;
  }

  int get _presentCount => _students
      .where(
        (s) =>
            s.status == AttendanceStatus.present ||
            s.status == AttendanceStatus.excused,
      )
      .length;

  List<_StudentAttendance> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _loadingClasses = true;
        _error = null;
      });

      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = _extractAcademicYearId(yearData);
      if (yearId == null) {
        throw Exception('Active academic year is missing id');
      }
      final offerings = await ApiService().getMyClassOfferings(yearId);

      if (!mounted) return;
      setState(() {
        _classOfferings = offerings
            .whereType<Map<String, dynamic>>()
            .where((o) => _stringValue(o['id']) != null)
            .toList();
        _loadingClasses = false;
        if (_classOfferings.isNotEmpty) {
          final first = _classOfferings.first;
          _selectedClassId = _stringValue(first['id']);
          _loadSession();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingClasses = false;
      });
    }
  }

  String _labelFor(Map<String, dynamic> offering) {
    final subject = offering['subject'];
    final grade = offering['grade'];
    final section = offering['section'];
    final subjectName = subject is Map ? (subject['name'] ?? '') : '';
    final gradeName = grade is Map ? (grade['name'] ?? '') : '';
    final sectionName = section is Map ? (section['name'] ?? '') : '';
    return '$subjectName $gradeName - $sectionName'.trim();
  }

  Future<void> _loadSession() async {
    if (_selectedClassId == null) return;
    try {
      setState(() {
        _loadingSession = true;
        _error = null;
      });

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Load enrolled students for this class
      final enrollments = await ApiService().getClassEnrollments(
        _selectedClassId!,
      );

      // 2. Check if a session already exists for today
      final sessions = await ApiService().getAttendanceSessions(
        classOfferingId: _selectedClassId!,
      );
      final todaySession = (sessions.cast<Map<String, dynamic>>()).firstWhere(
        (s) => s['date'] == today,
        orElse: () => <String, dynamic>{},
      );

      // 3. Load existing marks if session exists
      Map<String, Map<String, String>> existingMarks = {};
      if (todaySession.isNotEmpty) {
        final sessionId = _stringValue(todaySession['id']);
        if (sessionId == null) {
          throw Exception('Attendance session is missing id');
        }
        final marks = await ApiService().getAttendanceMarks(sessionId);
        for (final m in marks.cast<Map<String, dynamic>>()) {
          final sid = _stringValue(m['studentId']) ?? '';
          final status = _stringValue(m['status']) ?? 'present';
          final note = _stringValue(m['note']);
          if (sid.isNotEmpty) {
            existingMarks[sid] = {'status': status, 'note': note ?? ''};
          }
        }
      }

      if (!mounted) return;

      // 4. Build student list from enrollments
      final List<_StudentAttendance> students = [];
      for (final enr in enrollments.cast<Map<String, dynamic>>()) {
        final studentId = _stringValue(enr['studentId']) ?? '';
        final student = enr['student'] as Map<String, dynamic>?;
        final user = student?['user'] as Map<String, dynamic>? ?? student ?? {};
        final firstName = _stringValue(user['firstName']) ?? '';
        final lastName = _stringValue(user['lastName']) ?? '';
        final name = '$firstName $lastName'.trim();

        final markData = existingMarks[studentId];
        final statusStr = markData?['status'] ?? 'present';
        final note = markData?['note'];

        AttendanceStatus status;
        switch (statusStr.toLowerCase()) {
          case 'late':
            status = AttendanceStatus.late;
            break;
          case 'absent':
            status = AttendanceStatus.absent;
            break;
          case 'excused':
            status = AttendanceStatus.excused;
            break;
          default:
            status = AttendanceStatus.present;
        }

        students.add(
          _StudentAttendance(
            name: name.isNotEmpty ? name : 'Student',
            id: studentId,
            avatarUrl: '',
            status: status,
            note: note,
          ),
        );
      }

      setState(() {
        _students = students;
        _loadingSession = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSession = false;
      });
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var s in _students) {
        s.status = AttendanceStatus.present;
      }
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || _students.isEmpty) return;

    setState(() => _submitting = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if session already exists for today
      final sessions = await ApiService().getAttendanceSessions(
        classOfferingId: _selectedClassId!,
      );
      final existing = (sessions.cast<Map<String, dynamic>>()).firstWhere(
        (s) => s['date'] == today,
        orElse: () => <String, dynamic>{},
      );

      String sessionId;
      if (existing.isNotEmpty) {
        final existingId = _stringValue(existing['id']);
        if (existingId == null) {
          throw Exception('Attendance session is missing id');
        }
        sessionId = existingId;
      } else {
        final session = await ApiService().createAttendanceSession(
          classOfferingId: _selectedClassId!,
          date: today,
        );
        final createdId = _stringValue(session['id']);
        if (createdId == null) {
          throw Exception('Could not create attendance session id');
        }
        sessionId = createdId;
      }

      // PUT marks — backend expects { marks: [{studentId, status, note?}] }
      final marks = _students.map((s) {
        final mark = {'studentId': s.id, 'status': s.status.name};
        if (s.note != null && s.note!.isNotEmpty) {
          mark['note'] = s.note!;
        }
        return mark;
      }).toList();

      await ApiService().saveAttendanceMarks(sessionId, marks);

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingClasses) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Daily Attendance',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _classOfferings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Daily Attendance',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load classes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadClasses,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Daily Attendance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: OfflineBanner(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildClassDropdown(),
                  const SizedBox(height: 12),
                  _buildDateAndCount(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildListHeader(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingSession
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                  ? Center(
                      child: Text(
                        'No student records found for this class.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredStudents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return _StudentAttendanceTile(
                          student: student,
                          onStatusChanged: (status) {
                            setState(() => student.status = status);
                          },
                        );
                      },
                    ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: _classOfferings
              .map((c) {
                final id = _stringValue(c['id']);
                if (id == null) {
                  return null;
                }
                return DropdownMenuItem(value: id, child: Text(_labelFor(c)));
              })
              .whereType<DropdownMenuItem<String>>()
              .toList(),
          onChanged: (val) {
            if (val != null && val != _selectedClassId) {
              setState(() {
                _selectedClassId = val;
              });
              _loadSession();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateAndCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              _date,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$_presentCount/${_students.length} Present',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search student...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.tune, color: Colors.grey.shade600, size: 20),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'STUDENT LIST',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        GestureDetector(
          onTap: _markAllPresent,
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppColors.secondary,
              ),
              SizedBox(width: 4),
              Text(
                'Mark All Present',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: (_students.isEmpty || _submitting)
            ? null
            : _submitAttendance,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, size: 18),
        label: Text(
          _submitting ? 'Submitting...' : 'Submit Attendance',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

enum AttendanceStatus { present, late, absent, excused }

class _StudentAttendance {
  final String name;
  final String id;
  final String avatarUrl;
  AttendanceStatus status;
  String? note;

  _StudentAttendance({
    required this.name,
    required this.id,
    required this.avatarUrl,
    required this.status,
    this.note,
  });
}

class _StudentAttendanceTile extends StatelessWidget {
  final _StudentAttendance student;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _StudentAttendanceTile({
    required this.student,
    required this.onStatusChanged,
  });

  Future<void> _handleExcusedTap(BuildContext context) async {
    final controller = TextEditingController(text: student.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excused Absence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for ${student.name}\'s excused absence:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Doctor appointment, family emergency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      student.note = result.isEmpty ? null : result;
      onStatusChanged(AttendanceStatus.excused);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.id,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (student.status == AttendanceStatus.excused &&
                        student.note != null &&
                        student.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${student.note}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusButton(
                label: 'Present',
                isSelected: student.status == AttendanceStatus.present,
                color: AppColors.secondary,
                onTap: () => onStatusChanged(AttendanceStatus.present),
              ),
              const SizedBox(width: 6),
              _StatusButton(
                label: 'Late',
                isSelected: student.status == AttendanceStatus.late,
                color: AppColors.accent,
                onTap: () => onStatusChanged(AttendanceStatus.late),
              ),
              const SizedBox(width: 6),
              _StatusButton(
                label: 'Absent',
                isSelected: student.status == AttendanceStatus.absent,
                color: AppColors.error,
                onTap: () => onStatusChanged(AttendanceStatus.absent),
              ),
              const SizedBox(width: 6),
              _StatusButton(
                label: 'Excused',
                isSelected: student.status == AttendanceStatus.excused,
                color: Colors.blue.shade400,
                onTap: () => _handleExcusedTap(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(student.avatarUrl),
      );
    }
    final initials = student.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
