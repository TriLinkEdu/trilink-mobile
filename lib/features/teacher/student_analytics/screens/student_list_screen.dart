import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../shared/widgets/role_page_background.dart';
import 'student_analytics_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loadingClasses = true;
  bool _loadingStudents = false;
  String? _error;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;
  String _selectedClassName = '';
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _error = null;
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
        final first = classes.first;
        _selectedClassId = first['id'] as String? ?? '';
        _selectedClassName = _labelFor(first);
        await _loadStudents();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) return;
    setState(() {
      _loadingStudents = true;
      _error = null;
    });
    try {
      final response =
          await ApiService().getClassStudents(_selectedClassId!);
      if (!mounted) return;
      final list = (response['students'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _students = list;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingStudents = false;
      });
    }
  }

  String _labelFor(Map<String, dynamic> offering) {
    final displayName = offering['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final gradeName = offering['gradeName'] as String? ?? '';
    final sectionName = offering['sectionName'] as String? ?? '';
    final subjectName = offering['subjectName'] as String? ?? '';
    final classPart = [gradeName, sectionName].where((s) => s.isNotEmpty).join(' ');
    if (classPart.isNotEmpty && subjectName.isNotEmpty) return '$classPart | $subjectName';
    if (classPart.isNotEmpty) return classPart;
    if (subjectName.isNotEmpty) return subjectName;
    return 'Unnamed Class';
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name =
          '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.toLowerCase();
      final email = (s['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Students',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: _loadingClasses
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Class selector
                  if (_classOfferings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassId,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: theme.colorScheme.onSurfaceVariant),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            items: _classOfferings.map((c) {
                              final id = c['id'] as String? ?? '';
                              return DropdownMenuItem(
                                value: id,
                                child: Text(_labelFor(c)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null && val != _selectedClassId) {
                                setState(() {
                                  _selectedClassId = val;
                                  _selectedClassName = _labelFor(
                                    _classOfferings.firstWhere(
                                        (c) => c['id'] == val,
                                        orElse: () => {}),
                                  );
                                });
                                _loadStudents();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  // Count label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          _loadingStudents
                              ? 'Loading...'
                              : '${_filtered.length} student${_filtered.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Student list
                  Expanded(child: _buildList(theme)),
                ],
              ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load students',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No students match "$_searchQuery"'
                  : 'No students in this class',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(
            color: theme.colorScheme.outlineVariant, height: 1),
        itemBuilder: (_, index) {
          final s = list[index];
          final studentId = s['studentId'] as String? ?? '';
          final firstName = s['firstName'] as String? ?? '';
          final lastName = s['lastName'] as String? ?? '';
          final name = '$firstName $lastName'.trim();
          final email = s['email'] as String? ?? '';
          final phone = s['phone'] as String? ?? '';

          final initials =
              '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                  .toUpperCase();

          final colors = [
            AppColors.primary,
            AppColors.secondary,
            const Color(0xFF7C4DFF),
            const Color(0xFFFF6D00),
            const Color(0xFF00BFA5),
          ];
          final color = colors[index % colors.length];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentAnalyticsScreen(
                    studentId: studentId,
                    studentName: name,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Unknown Student',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
