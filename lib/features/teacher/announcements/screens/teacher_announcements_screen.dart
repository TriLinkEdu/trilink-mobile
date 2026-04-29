import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../screens/create_announcement_screen.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Sent', 'Scheduled', 'Draft'];

  bool _loading = true;
  String? _error;
  List<_AnnouncementItem> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await ApiService().getAnnouncementsForMe();
      setState(() {
        _announcements = raw
            .map((a) => _AnnouncementItem.fromJson(a as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _patchAnnouncement(_AnnouncementItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final bodyCtrl = TextEditingController(text: item.preview);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: bodyCtrl, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true || item.id.isEmpty) return;
    try {
      await ApiService().updateAnnouncement(item.id, {
        'title': titleCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
      });
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  List<_AnnouncementItem> get _filteredAnnouncements {
    if (_selectedFilter == 'All') return _announcements;
    return _announcements.where((a) {
      switch (_selectedFilter) {
        case 'Sent':
          return a.status == _AnnouncementStatus.sent;
        case 'Scheduled':
          return a.status == _AnnouncementStatus.scheduled;
        case 'Draft':
          return a.status == _AnnouncementStatus.draft;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Announcements',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredAnnouncements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No $_selectedFilter announcements',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredAnnouncements.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _AnnouncementCard(
                                announcement: _filteredAnnouncements[index],
                                onEdit: () => _patchAnnouncement(_filteredAnnouncements[index]),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
          );
          if (created == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _AnnouncementItem announcement;
  final VoidCallback? onEdit;

  const _AnnouncementCard({required this.announcement, this.onEdit});

  Color get _statusColor {
    switch (announcement.status) {
      case _AnnouncementStatus.sent:
        return AppColors.secondary;
      case _AnnouncementStatus.scheduled:
        return AppColors.primary;
      case _AnnouncementStatus.draft:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (announcement.status) {
      case _AnnouncementStatus.sent:
        return 'Sent';
      case _AnnouncementStatus.scheduled:
        return 'Scheduled';
      case _AnnouncementStatus.draft:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: announcement.audiences.map((audience) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  audience,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                announcement.dateTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (announcement.attachments > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${announcement.attachments} file${announcement.attachments > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}

enum _AnnouncementStatus { sent, scheduled, draft }

class _AnnouncementItem {
  final String id;
  final String title;
  final String preview;
  final List<String> audiences;
  final String dateTime;
  final _AnnouncementStatus status;
  final int attachments;

  _AnnouncementItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.audiences,
    required this.dateTime,
    required this.status,
    required this.attachments,
  });

  factory _AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?) ?? 'sent';
    _AnnouncementStatus status;
    switch (statusStr.toLowerCase()) {
      case 'scheduled':
        status = _AnnouncementStatus.scheduled;
        break;
      case 'draft':
        status = _AnnouncementStatus.draft;
        break;
      default:
        status = _AnnouncementStatus.sent;
    }

    final audienceRaw = json['audiences'] ?? json['targetAudience'] ?? json['audience'] ?? 'all';
    final audiences = (audienceRaw is List)
        ? audienceRaw
              .map((a) => a is Map ? (a['name'] ?? a.toString()) : a.toString())
              .toList()
              .cast<String>()
        : [audienceRaw.toString()];

    final attachmentsRaw = json['attachments'];
    final attachmentCount = attachmentsRaw is List ? attachmentsRaw.length : 0;

    return _AnnouncementItem(
      id: json['id'] as String? ?? '',
      title: json['title'] ?? '',
      preview: json['message'] ?? json['body'] ?? json['content'] ?? '',
      audiences: audiences,
      dateTime: json['createdAt'] ?? json['scheduledAt'] ?? json['publishAt'] ?? '',
      status: status,
      attachments: attachmentCount,
    );
  }
}
