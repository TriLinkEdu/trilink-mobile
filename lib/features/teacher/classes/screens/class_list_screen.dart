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
  
  // Search & Sort
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true; // true = A→Z, false = Z→A

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  
  List<Map<String, dynamic>> get _filteredAndSortedClasses {
    var result = _classes;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) {
        final className = _className(c).toLowerCase();
        final classPeriod = _classPeriod(c).toLowerCase();
        final subjectName = (c['subjectName'] as String? ?? '').toLowerCase();
        final gradeName = (c['gradeName'] as String? ?? '').toLowerCase();
        final sectionName = (c['sectionName'] as String? ?? '').toLowerCase();
        
        return className.contains(query) ||
               classPeriod.contains(query) ||
               subjectName.contains(query) ||
               gradeName.contains(query) ||
               sectionName.contains(query);
      }).toList();
    }
    
    // Apply sorting
    result.sort((a, b) {
      final aName = _className(a).toLowerCase();
      final bName = _className(b).toLowerCase();
      return _sortAscending ? aName.compareTo(bName) : bName.compareTo(aName);
    });
    
    return result;
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
            Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade300),
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

    final displayedClasses = _filteredAndSortedClasses;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  hintText: 'Search classes...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey.shade600, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      // Sort button
                      IconButton(
                        icon: Icon(
                          _sortAscending
                              ? Icons.sort_by_alpha
                              : Icons.sort_by_alpha,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        tooltip: _sortAscending ? 'A → Z' : 'Z → A',
                        onPressed: () {
                          setState(() => _sortAscending = !_sortAscending);
                        },
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Count and sort indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${displayedClasses.length} class${displayedClasses.length == 1 ? '' : 'es'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortAscending ? 'A → Z' : 'Z → A',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Classes list
          Expanded(
            child: displayedClasses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No classes match "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedClasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = displayedClasses[i];
                      final color = _classColor(i);
                      return _buildClassCard(c, color);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClassCard(Map<String, dynamic> c, Color color) {
    final classId = c['id'] as String? ?? '';
    final subjectId = c['subjectId'] as String? ?? '';
    final subjectName = c['subjectName'] as String? ?? _className(c);
    final className = _className(c);
    final classPeriod = _classPeriod(c);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: classId.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherClassDetailScreen(
                        classId: classId,
                        subjectId: subjectId,
                        subjectName: subjectName,
                        className: className,
                        classPeriod: classPeriod,
                      ),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_outlined,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (classPeriod.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          classPeriod,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
