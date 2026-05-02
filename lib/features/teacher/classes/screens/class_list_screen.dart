import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';
import 'teacher_class_detail_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = (yearData['id'] ?? yearData['data']?['id']) as String?;
      if (yearId == null || yearId.isEmpty) {
        throw Exception('Active academic year is missing id');
      }

      final offerings = await ApiService().getMyClassOfferings(yearId);

      if (!mounted) return;
      setState(() {
        _classes = offerings.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _className(Map<String, dynamic> offering) {
    // Backend returns flat fields: subjectName, gradeName, sectionName, displayName
    final displayName = offering['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final subjectName = offering['subjectName'] as String?;
    return subjectName ?? 'Unknown';
  }

  String _classPeriod(Map<String, dynamic> offering) {
    // Backend returns flat fields
    final gradeName = offering['gradeName'] as String? ?? '';
    final sectionName = offering['sectionName'] as String? ?? '';

    if (gradeName.isEmpty && sectionName.isEmpty) return '';
    if (sectionName.isEmpty) return gradeName;
    if (gradeName.isEmpty) return sectionName;

    return '$gradeName - $sectionName';
  }

  Color _classColor(int index) {
    const colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // This screen is embedded in TeacherMainScreen's IndexedStack
    // So it should NOT have its own AppBar or Scaffold
    // The parent TeacherMainScreen handles the Scaffold and drawer
    return _buildBody();
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
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
                onPressed: _loadData,
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
      );
    }

    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No classes found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no class offerings for the current academic year.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final c = _classes[i];
          final color = _classColor(i);
          final teacher = c['teacher'];
          final teacherName = teacher is Map
              ? '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'
                    .trim()
              : '';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.class_outlined, color: color),
              ),
              title: Text(
                _className(c),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_classPeriod(c)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                final classId = c['id'] as String? ?? '';
                final subjectId = c['subjectId'] as String? ?? '';
                final subjectName = c['subjectName'] as String? ?? _className(c);
                if (classId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherClassDetailScreen(
                        classId: classId,
                        subjectId: subjectId,
                        subjectName: subjectName,
                        className: _className(c),
                        classPeriod: _classPeriod(c),
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
