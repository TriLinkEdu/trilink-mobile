import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../repositories/student_announcements_repository.dart';
import '../repositories/mock_student_announcements_repository.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  final StudentAnnouncementsRepository? repository;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  }) : repository = null;

  const AnnouncementDetailScreen.withRepo({
    super.key,
    required this.announcementId,
    required this.repository,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late final StudentAnnouncementsRepository _repo;
  AnnouncementModel? _announcement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockStudentAnnouncementsRepository();
    _loadAnnouncement();
  }

  Future<void> _loadAnnouncement() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final all = await _repo.fetchAnnouncements();
      final match = all.where((a) => a.id == widget.announcementId);
      if (match.isNotEmpty) {
        _announcement = match.first;
      } else {
        _error = 'Announcement not found';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final a = _announcement!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.category != null)
            Chip(
              label: Text(a.category!.toUpperCase(), style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(height: 8),
          Text(a.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(a.authorName[0], style: TextStyle(color: theme.colorScheme.primary)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.authorName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(a.authorRole, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(a.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(a.body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
