import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/course_resource_detail_cubit.dart';
import '../models/course_resource_model.dart';
import '../repositories/student_courses_repository.dart';

class CourseResourceDetailScreen extends StatelessWidget {
  final String resourceId;

  const CourseResourceDetailScreen({
    super.key,
    required this.resourceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CourseResourceDetailCubit(
        sl<StudentCoursesRepository>(),
        resourceId,
      )..loadResource(),
      child: const _CourseResourceDetailView(),
    );
  }
}

class _CourseResourceDetailView extends StatefulWidget {
  const _CourseResourceDetailView();

  @override
  State<_CourseResourceDetailView> createState() =>
      _CourseResourceDetailViewState();
}

class _CourseResourceDetailViewState extends State<_CourseResourceDetailView> {
  bool _isOpening = false;

  Future<void> _openResource(CourseResourceModel resource) async {
    setState(() => _isOpening = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isOpening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened "${resource.title}" (${resource.typeLabel})')),
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

    return BlocBuilder<CourseResourceDetailCubit, CourseResourceDetailState>(
      builder: (context, state) {
        if (state.status == CourseResourceDetailStatus.loading ||
            state.status == CourseResourceDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resource'), centerTitle: true),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            ),
          );
        }
        if (state.status == CourseResourceDetailStatus.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resource'), centerTitle: true),
            body: AppErrorWidget(
              message: state.errorMessage ??
                  'Unable to load resource details.',
            ),
          );
        }
        final r = state.resource!;
        return Scaffold(
          appBar: AppBar(title: const Text('Resource'), centerTitle: true),
          body: _buildContent(theme, r),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, CourseResourceModel r) {
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
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(_iconForType(r.type), size: 32, color: theme.colorScheme.primary),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    AppSpacing.gapXs,
                    Text(r.subjectName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapXxl,
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
              onPressed: _isOpening ? null : () => _openResource(r),
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
          AppSpacing.hGapMd,
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
