import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';
import 'create_announcement_screen.dart';
import 'teacher_announcement_detail_screen.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum _AnnStatus { sent, scheduled }

class _Ann {
  final String id;
  final String title;
  final String body;
  final String audience;
  final String? classOfferingId;
  final String? targetGrade;
  final DateTime? publishAt;
  final DateTime createdAt;
  final bool realtimeSent;
  final String authorId;

  _AnnStatus get status {
    if (publishAt != null && publishAt!.isAfter(DateTime.now())) {
      return _AnnStatus.scheduled;
    }
    return _AnnStatus.sent;
  }

  String get audienceLabel {
    switch (audience) {
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
        return targetGrade != null ? 'Grade $targetGrade' : 'Grade';
      default:
        return audience;
    }
  }

  IconData get audienceIcon {
    switch (audience) {
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

  _Ann({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.classOfferingId,
    this.targetGrade,
    this.publishAt,
    required this.createdAt,
    required this.realtimeSent,
    required this.authorId,
  });

  factory _Ann.fromJson(Map<String, dynamic> json) {
    DateTime? publishAt;
    final paStr = json['publishAt'] as String?;
    if (paStr != null && paStr.isNotEmpty) {
      publishAt = DateTime.tryParse(paStr)?.toLocal();
    }
    DateTime createdAt = DateTime.now();
    final caStr = json['createdAt'] as String?;
    if (caStr != null && caStr.isNotEmpty) {
      createdAt = DateTime.tryParse(caStr)?.toLocal() ?? DateTime.now();
    }
    return _Ann(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      audience: json['audience'] as String? ?? 'all',
      classOfferingId: json['classOfferingId'] as String?,
      targetGrade: json['targetGrade'] as String?,
      publishAt: publishAt,
      createdAt: createdAt,
      realtimeSent: json['realtimeSent'] as bool? ?? false,
      authorId: json['authorId'] as String? ?? '',
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState extends State<TeacherAnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 'all' | 'sent' | 'scheduled'
  String _myFilter = 'all';
  String _search = '';
  bool _loading = true;
  String? _error;
  List<_Ann> _announcements = [];
  String _currentUserId = '';
  final TextEditingController _searchController = TextEditingController();

  List<_Ann> get _myAnnouncements =>
      _announcements.where((a) => a.authorId == _currentUserId).toList();

  List<_Ann> get _receivedAnnouncements =>
      _announcements.where((a) => a.authorId != _currentUserId).toList();

  List<_Ann> get _filteredMine {
    return _myAnnouncements.where((a) {
      final matchesFilter = _myFilter == 'all' ||
          (_myFilter == 'sent' && a.status == _AnnStatus.sent) ||
          (_myFilter == 'scheduled' && a.status == _AnnStatus.scheduled);
      final matchesSearch = _search.isEmpty ||
          a.title.toLowerCase().contains(_search.toLowerCase()) ||
          a.body.toLowerCase().contains(_search.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<_Ann> get _filteredReceived {
    if (_search.isEmpty) return _receivedAnnouncements;
    return _receivedAnnouncements.where((a) =>
        a.title.toLowerCase().contains(_search.toLowerCase()) ||
        a.body.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = AuthService().currentUser?.id ?? '';
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await ApiService().getAnnouncementsForMe();
      setState(() {
        _announcements = raw
            .map((a) => _Ann.fromJson(a as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
    );
    if (created == true) _loadData();
  }

  Future<void> _openEdit(_Ann ann) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAnnouncementScreen(existing: ann.toEditMap()),
      ),
    );
    if (updated == true) _loadData();
  }

  Future<void> _confirmDelete(_Ann ann) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${ann.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().deleteAnnouncement(ann.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myCount = _myAnnouncements.length;
    final receivedCount = _receivedAnnouncements.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(text: 'Mine ($myCount)'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('From Admin ($receivedCount)'),
                  if (receivedCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // ── Search bar (shared) ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search announcements...',
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
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Tab content ──
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyTab(),
                          _buildReceivedTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── My Announcements Tab ──────────────────────────────────────────────────

  Widget _buildMyTab() {
    final filtered = _filteredMine;
    return Column(
      children: [
        // Status filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _myFilter == 'all',
                color: AppColors.primary,
                onTap: () => setState(() => _myFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sent',
                selected: _myFilter == 'sent',
                color: AppColors.success,
                onTap: () => setState(() => _myFilter = 'sent'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Scheduled',
                selected: _myFilter == 'scheduled',
                color: AppColors.accent,
                onTap: () => setState(() => _myFilter = 'scheduled'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(
                  _search.isNotEmpty
                      ? 'No results for "$_search"'
                      : 'No announcements yet',
                  subtitle: 'Tap + New to create one',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AnnCard(
                      ann: filtered[i],
                      isOwn: true,
                      onEdit: () => _openEdit(filtered[i]),
                      onDelete: () => _confirmDelete(filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── From Admin Tab ────────────────────────────────────────────────────────

  Widget _buildReceivedTab() {
    final filtered = _filteredReceived;
    return filtered.isEmpty
        ? _buildEmpty(
            _search.isNotEmpty
                ? 'No results for "$_search"'
                : 'No announcements from admin',
            subtitle: 'School-wide announcements will appear here',
          )
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AnnCard(
                ann: filtered[i],
                isOwn: false,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String message, {String? subtitle}) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined,
              size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style:
                    TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

// ─── Announcement Card ────────────────────────────────────────────────────────

class _AnnCard extends StatelessWidget {
  final _Ann ann;
  final bool isOwn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnCard({
    required this.ann,
    required this.isOwn,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor =>
      ann.status == _AnnStatus.scheduled ? AppColors.accent : AppColors.success;
  String get _statusLabel =>
      ann.status == _AnnStatus.scheduled ? 'Scheduled' : 'Sent';
  IconData get _statusIcon => ann.status == _AnnStatus.scheduled
      ? Icons.schedule
      : Icons.check_circle_outline;

  String get _timeLabel {
    final dt = ann.status == _AnnStatus.scheduled && ann.publishAt != null
        ? ann.publishAt!
        : ann.createdAt;
    return DateFormat('MMM d, yyyy  •  h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherAnnouncementDetailScreen(
              announcement: ann.toEditMap()
                ..addAll({
                  'createdAt': ann.createdAt.toIso8601String(),
                  'body': ann.body,
                }),
              isOwn: isOwn,
              onEdit: isOwn ? onEdit : null,
              onDelete: isOwn ? onDelete : null,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOwn ? ann.audienceIcon : Icons.admin_panel_settings_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ann.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.group_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            ann.audienceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badges + menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 11, color: _statusColor),
                          const SizedBox(width: 3),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwn)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        padding: EdgeInsets.zero,
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') onEdit();
                          if (v == 'delete') onDelete();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (ann.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                ann.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Icon(
                  ann.status == _AnnStatus.scheduled
                      ? Icons.schedule
                      : Icons.access_time,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  ann.status == _AnnStatus.scheduled
                      ? 'Sends $_timeLabel'
                      : _timeLabel,
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
          color: selected ? color.withValues(alpha: 0.12) : theme.colorScheme.surface,
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

// ─── Extension ───────────────────────────────────────────────────────────────

extension _AnnEditMap on _Ann {
  Map<String, dynamic> toEditMap() => {
        'id': id,
        'title': title,
        'body': body,
        'audience': audience,
        'classOfferingId': classOfferingId,
        'targetGrade': targetGrade,
        'publishAt': publishAt?.toUtc().toIso8601String(),
      };
}
