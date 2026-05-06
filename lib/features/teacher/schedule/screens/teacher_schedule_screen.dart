import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

enum _ScheduleFilter { all, mine, byClass }

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  bool _loading = true;
  String? _error;

  String? _academicYearId;
  String? _academicYearLabel;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;

  List<Map<String, dynamic>> _events = [];

  _ScheduleFilter _filter = _ScheduleFilter.mine;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = (yearData['id'] ?? yearData['data']?['id']) as String?;
      final yearLabel =
          (yearData['name'] ?? yearData['label'] ?? yearData['title']) as String?;
      if (yearId == null) {
        throw Exception('No active academic year found');
      }

      final offerings = await ApiService().getMyClassOfferings(yearId);
      if (!mounted) return;

      setState(() {
        _academicYearId = yearId;
        _academicYearLabel = yearLabel ?? 'Current Year';
        _classOfferings = offerings.cast<Map<String, dynamic>>();
        if (_classOfferings.isNotEmpty) {
          _selectedClassId = _classOfferings.first['id'] as String?;
        }
      });

      await _loadEvents();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (_academicYearId == null) return;
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      String? classFilter;
      if (_filter == _ScheduleFilter.byClass) {
        classFilter = _selectedClassId;
      }

      final raw = await ApiService().getCalendarEvents(
        academicYearId: _academicYearId,
        classOfferingId: classFilter,
      );

      var events = raw.cast<Map<String, dynamic>>();

      // Client-side filter for "mine": keep only events that belong to teacher's classes
      if (_filter == _ScheduleFilter.mine) {
        final myIds = _classOfferings
            .map((c) => c['id'] as String?)
            .whereType<String>()
            .toSet();
        events = events.where((e) {
          final cid = e['classOfferingId'] as String?;
          return cid == null || myIds.contains(cid);
        }).toList();
      }

      events.sort((a, b) {
        final ad = _eventDate(a) ?? DateTime(2100);
        final bd = _eventDate(b) ?? DateTime(2100);
        return ad.compareTo(bd);
      });

      if (!mounted) return;
      setState(() {
        _events = events;
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

  DateTime? _eventDate(Map<String, dynamic> e) {
    final raw = e['date'] ?? e['startDate'] ?? e['startsAt'];
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _classNameFor(String? classOfferingId) {
    if (classOfferingId == null) return 'School-wide';
    final c = _classOfferings.firstWhere(
      (m) => m['id'] == classOfferingId,
      orElse: () => <String, dynamic>{},
    );
    if (c.isEmpty) return 'Class';
    return (c['displayName'] ??
            c['subjectName'] ??
            c['name'] ??
            'Class') as String;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 12),
                      _buildFilterChips(theme),
                      const SizedBox(height: 12),
                      if (_filter == _ScheduleFilter.byClass)
                        _buildClassDropdown(theme),
                      const SizedBox(height: 12),
                      ..._buildEventList(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              onPressed: _bootstrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final teacher = AuthService().currentUser?.fullName ?? 'Teacher';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primaryDark.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _academicYearLabel ?? 'Schedule',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacher,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_events.length} events',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          icon: Icons.all_inclusive,
          selected: _filter == _ScheduleFilter.all,
          onTap: () {
            setState(() => _filter = _ScheduleFilter.all);
            _loadEvents();
          },
        ),
        _FilterChip(
          label: 'My Classes',
          icon: Icons.person,
          selected: _filter == _ScheduleFilter.mine,
          onTap: () {
            setState(() => _filter = _ScheduleFilter.mine);
            _loadEvents();
          },
        ),
        _FilterChip(
          label: 'By Class',
          icon: Icons.class_,
          selected: _filter == _ScheduleFilter.byClass,
          onTap: () {
            setState(() => _filter = _ScheduleFilter.byClass);
            _loadEvents();
          },
        ),
      ],
    );
  }

  Widget _buildClassDropdown(ThemeData theme) {
    if (_classOfferings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No classes assigned to you',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.expand_more),
          items: _classOfferings.map((c) {
            final id = c['id'] as String;
            final label = (c['displayName'] ??
                    c['subjectName'] ??
                    c['name'] ??
                    'Class') as String;
            return DropdownMenuItem<String>(value: id, child: Text(label));
          }).toList(),
          onChanged: (v) {
            setState(() => _selectedClassId = v);
            _loadEvents();
          },
        ),
      ),
    );
  }

  List<Widget> _buildEventList(ThemeData theme) {
    if (_events.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No scheduled events',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Group events by date
    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final e in _events) {
      final d = _eventDate(e);
      final key = d != null ? DateFormat('yyyy-MM-dd').format(d) : 'Unknown';
      byDate.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = byDate.keys.toList()..sort();

    final widgets = <Widget>[];
    for (final key in sortedKeys) {
      final dt = DateTime.tryParse(key);
      final headerLabel = dt != null
          ? DateFormat('EEEE, MMM d').format(dt)
          : 'Unscheduled';
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            headerLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      for (final e in byDate[key]!) {
        widgets.add(_buildEventCard(theme, e));
      }
    }
    return widgets;
  }

  Widget _buildEventCard(ThemeData theme, Map<String, dynamic> e) {
    final title = (e['title'] ?? 'Untitled') as String;
    final type = (e['type'] as String? ?? 'other').toLowerCase();
    final time = e['time'] as String?;
    final desc = e['description'] as String?;
    final classOfferingId = e['classOfferingId'] as String?;
    final className = _classNameFor(classOfferingId);

    final typeColor = _typeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (time != null) ...[
                      Icon(Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.class_,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        className,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'class':
      case 'lecture':
      case 'session':
        return AppColors.primary;
      case 'exam':
      case 'test':
        return AppColors.error;
      case 'assignment':
        return Colors.purple;
      case 'holiday':
        return AppColors.secondary;
      case 'meeting':
        return AppColors.warning;
      default:
        return Colors.blueGrey;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
