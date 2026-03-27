import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course_resource_model.dart';
import '../repositories/student_courses_repository.dart';
import '../repositories/mock_student_courses_repository.dart';

class CourseResourceDetailScreen extends StatefulWidget {
  final String resourceId;
  final StudentCoursesRepository? repository;

  const CourseResourceDetailScreen({
    super.key,
    required this.resourceId,
  }) : repository = null;

  @override
  State<CourseResourceDetailScreen> createState() => _CourseResourceDetailScreenState();
}

class _CourseResourceDetailScreenState extends State<CourseResourceDetailScreen> {
  late final StudentCoursesRepository _repo;
  CourseResourceModel? _resource;
  bool _isLoading = true;
  bool _isOpening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockStudentCoursesRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final all = await _repo.fetchCourseResources();
      final match = all.where((r) => r.id == widget.resourceId);
      _resource = match.isNotEmpty ? match.first : null;
      if (_resource == null) _error = 'Resource not found';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openResource() async {
    setState(() => _isOpening = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isOpening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened "${_resource!.title}" (${_resource!.typeLabel})')),
      );
    }
  }

  IconData _iconForType(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf_rounded;
      case ResourceType.video:
        return Icons.play_circle_rounded;
      case ResourceType.link:
        return Icons.link_rounded;
      case ResourceType.document:
        return Icons.description_rounded;
      case ResourceType.presentation:
        return Icons.slideshow_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Resource'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final r = _resource!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(r.type), size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(r.subjectName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoRow(icon: Icons.category_rounded, label: 'Type', value: r.typeLabel),
          if (r.fileSize != null)
            _InfoRow(icon: Icons.storage_rounded, label: 'Size', value: r.fileSize!),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Uploaded',
            value: DateFormat('MMM dd, yyyy').format(r.uploadedAt),
          ),
          if (r.description != null) ...[
            const Divider(height: 32),
            Text(r.description!, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isOpening ? null : _openResource,
              icon: _isOpening
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.open_in_new_rounded),
              label: Text(_isOpening ? 'Opening...' : 'Open Resource'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
