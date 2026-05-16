import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';

class TeacherFeedbackScreen extends StatefulWidget {
  const TeacherFeedbackScreen({super.key});

  @override
  State<TeacherFeedbackScreen> createState() => _TeacherFeedbackScreenState();
}

class _TeacherFeedbackScreenState extends State<TeacherFeedbackScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  // Filter: 'all' | 'open' | 'resolved'
  String _filter = 'all';

  late final TabController _tabController;

  List<Map<String, dynamic>> _sentItems = [];

  bool get _isReceived => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        // Reset filter when switching tabs
        if (!_tabController.indexIsChanging) {
          setState(() => _filter = 'all');
        }
      });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService().getTeacherFeedback(),
        ApiService().getMyFeedback(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0].cast<Map<String, dynamic>>();
        _sentItems = results[1].cast<Map<String, dynamic>>();
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

  List<Map<String, dynamic>> get _filtered {
    // For the sent tab, only show school-category feedback
    final source = _isReceived
        ? _items
        : _sentItems
              .where((f) => (f['category'] as String? ?? '') == 'school')
              .toList();

    if (_filter == 'all') return source;
    return source.where((f) => f['status'] == _filter).toList();
  }

  Future<void> _showComposeFeedback() async {
    final messageCtrl = TextEditingController();
    bool isAnonymous = false;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.feedback_outlined,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Feedback to School',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Your feedback goes to school administration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Write your feedback to the school administration...',
                    hintStyle: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isAnonymous,
                      onChanged: (v) =>
                          setModalState(() => isAnonymous = v ?? false),
                      activeColor: Theme.of(ctx).colorScheme.primary,
                    ),
                    const Text('Submit anonymously'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: submitting
                        ? null
                        : () async {
                            final msg = messageCtrl.text.trim();
                            if (msg.isEmpty) return;
                            setModalState(() => submitting = true);
                            try {
                              await ApiService().submitFeedback({
                                'category': 'school',
                                'message': msg,
                                'isAnonymous': isAnonymous,
                              });
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Feedback sent to school administration',
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              _load();
                            } catch (e) {
                              setModalState(() => submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to send: $e'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: submitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        // ── Primary navigation: TabBar in AppBar ──────────────────────────
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Received'),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(count: _items.length, active: _isReceived),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sent to School'),
                  if (_sentSchoolCount > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: _sentSchoolCount, active: !_isReceived),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposeFeedback,
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary),
        label: Text(
          'Send to School',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Secondary filter: pill chips ─────────────────────────────────
          _buildFilterBar(theme),
          // ── Content ──────────────────────────────────────────────────────
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  int get _sentSchoolCount => _sentItems
      .where((f) => (f['category'] as String? ?? '') == 'school')
      .length;

  Widget _buildFilterBar(ThemeData theme) {
    // Use the correct source based on active tab
    final source = _isReceived
        ? _items
        : _sentItems
              .where((f) => (f['category'] as String? ?? '') == 'school')
              .toList();
    final allCount = source.length;
    final openCount = source.where((f) => f['status'] == 'open').length;
    final resolvedCount = source.where((f) => f['status'] == 'resolved').length;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == 'all',
            count: allCount,
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Open',
            selected: _filter == 'open',
            count: openCount,
            color: Colors.orange,
            onTap: () => setState(() => _filter = 'open'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Resolved',
            selected: _filter == 'resolved',
            count: resolvedCount,
            color: Colors.green,
            onTap: () => setState(() => _filter = 'resolved'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(theme);
    }

    final list = _filtered;

    if (list.isEmpty) {
      return _buildEmpty(theme);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _FeedbackCard(item: list[i], isSent: !_isReceived),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load feedback',
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
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

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            !_isReceived
                ? 'No feedback sent to school yet'
                : _filter == 'all'
                ? 'No feedback yet'
                : 'No ${_filter} feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !_isReceived
                ? 'Tap "Send to School" to submit feedback\nto school administration.'
                : 'Feedback from students and parents\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge for tab count ─────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  final bool active;
  const _Badge({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.count,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.9)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Feedback card ──────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSent;

  const _FeedbackCard({required this.item, this.isSent = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = item['category'] as String? ?? '';
    final isAnonymous = item['isAnonymous'] as bool? ?? true;
    final senderRole = item['senderRole'] as String? ?? '';
    final status = item['status'] as String? ?? 'open';
    final message = item['message'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;
    final sender = item['sender'] as Map<String, dynamic>?;

    // Sender display
    String senderName;
    if (isSent) {
      senderName = isAnonymous ? 'You (Anonymous)' : 'You';
    } else if (isAnonymous || sender == null) {
      senderName = 'Anonymous ${_capitalize(senderRole)}';
    } else {
      senderName = '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'
          .trim();
      if (senderName.isEmpty) senderName = 'Unknown';
    }

    // Role icon + color
    Color roleColor;
    IconData roleIcon;
    if (isSent) {
      roleColor = theme.colorScheme.primary;
      roleIcon = Icons.send_outlined;
    } else {
      roleColor = senderRole == 'student'
          ? theme.colorScheme.primary
          : senderRole == 'parent'
          ? theme.colorScheme.secondary
          : Colors.grey;
      roleIcon = senderRole == 'student'
          ? Icons.school_outlined
          : senderRole == 'parent'
          ? Icons.family_restroom_outlined
          : Icons.person_outline;
    }

    // Status badge
    final statusColor = status == 'resolved'
        ? Colors.green
        : status == 'in_progress'
        ? Colors.orange
        : Colors.blue;

    // Date
    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(roleIcon, size: 18, color: roleColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Category badge for sent items
              if (isSent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _capitalize(category),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(status.replaceAll('_', ' ')),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          if (isAnonymous && !isSent) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Submitted anonymously',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
