import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/announcement_detail_cubit.dart';
import '../models/announcement_model.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../repositories/student_announcements_repository.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnnouncementDetailCubit(
        sl<StudentAnnouncementsRepository>(),
        announcementId,
      )..loadAnnouncement(),
      child: const _AnnouncementDetailView(),
    );
  }
}

class _AnnouncementDetailView extends StatelessWidget {
  const _AnnouncementDetailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AnnouncementDetailCubit, AnnouncementDetailState>(
      builder: (context, state) {
        if (state.status == AnnouncementDetailStatus.loading ||
            state.status == AnnouncementDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Announcement'), centerTitle: true),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            ),
          );
        }
        if (state.status == AnnouncementDetailStatus.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Announcement'), centerTitle: true),
            body: AppErrorWidget(
              message: state.errorMessage ?? 'Unable to load announcement.',
              onRetry: () => context.read<AnnouncementDetailCubit>().loadAnnouncement(),
            ),
          );
        }
        final a = state.announcement!;
        return Scaffold(
          appBar: AppBar(title: const Text('Announcement'), centerTitle: true),
          body: _buildContent(theme, a),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, AnnouncementModel a) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.category != null)
            Chip(
              label: Text(a.category!.toUpperCase(), style: theme.textTheme.labelSmall),
              visualDensity: VisualDensity.compact,
            ),
          AppSpacing.gapSm,
          Text(a.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.gapMd,
          Row(
            children: [
              ProfileAvatar(
                radius: 16,
                
                fallbackText: a.authorName,
              ),
              AppSpacing.hGapSm,
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
