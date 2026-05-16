import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/feedback_cubit.dart';
import '../models/feedback_model.dart';
import '../repositories/student_feedback_repository.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../shared/widgets/profile_avatar.dart';

class StudentFeedbackScreen extends StatelessWidget {
  const StudentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FeedbackCubit(sl<StudentFeedbackRepository>())..loadIfNeeded(),
      child: const _StudentFeedbackView(),
    );
  }
}

class _StudentFeedbackView extends StatefulWidget {
  const _StudentFeedbackView();

  @override
  State<_StudentFeedbackView> createState() => _StudentFeedbackViewState();
}

class _StudentFeedbackViewState extends State<_StudentFeedbackView> {
  int _selectedRating = 4;
  bool _showBanner = true;
  final _whatWentWellController = TextEditingController();
  final _whatCouldImproveController = TextEditingController();
  final ApiClient _api = ApiClient();
  List<_SubjectOption> _subjects = const [];
  _SubjectOption? _selectedSubject;
  bool _subjectsLoading = true;
  String? _subjectsError;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _whatWentWellController.dispose();
    _whatCouldImproveController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _subjectsLoading = true;
      _subjectsError = null;
    });
    try {
      final rows = await _api.getList(ApiConstants.mySubjects);
      final byId = <String, _SubjectOption>{};
      for (final raw in rows.whereType<Map<String, dynamic>>()) {
        final id = (raw['subjectId'] ?? '').toString();
        final name = (raw['subjectName'] ?? '').toString();
        final code = (raw['subjectCode'] ?? '').toString();
        if (id.isEmpty || name.isEmpty) continue;
        byId[id] = _SubjectOption(id: id, name: name, code: code);
      }
      final subjects = byId.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _subjectsLoading = false;
        if (_selectedSubject == null && subjects.isNotEmpty) {
          _selectedSubject = subjects.first;
        } else if (_selectedSubject != null) {
          _selectedSubject = subjects.firstWhere(
            (s) => s.id == _selectedSubject!.id,
            orElse: () => subjects.isNotEmpty ? subjects.first : _selectedSubject!,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subjectsLoading = false;
        _subjectsError = 'Unable to load subjects.';
      });
    }
  }

  void _submitFeedback() {
    final positive = _whatWentWellController.text.trim();
    final improvement = _whatCouldImproveController.text.trim();
    final selected = _selectedSubject;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }

    if (positive.isEmpty && improvement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one feedback comment.'),
        ),
      );
      return;
    }

    final comment = [
      if (positive.isNotEmpty) 'What went well: $positive',
      if (improvement.isNotEmpty) 'Could improve: $improvement',
    ].join('\n');

    context.read<FeedbackCubit>().submitFeedback(
      subjectId: selected.id,
      subjectName: selected.name,
      rating: _selectedRating,
      comment: comment,
    );
  }

  void _showAllFeedbackHistory() {
    final theme = Theme.of(context);
    final feedbackHistory = context.read<FeedbackCubit>().state.feedbackHistory;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'All Feedback History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: feedbackHistory.isEmpty
                  ? const EmptyStateWidget(
                      illustration: ClipboardIllustration(),
                      icon: Icons.rate_review_rounded,
                      title: 'No feedback yet',
                      subtitle: 'Feedback you submit will appear here.',
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: feedbackHistory.length,
                      separatorBuilder: (_, _) => AppSpacing.gapMd,
                      itemBuilder: (context, index) {
                        final fb = feedbackHistory[index];
                        return StaggeredFadeSlide(
                          index: index,
                          child: _FeedbackHistoryTile(feedback: fb),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackCubit, FeedbackState>(
      listener: (context, feedbackState) {
        if (feedbackState.submissionStatus ==
            FeedbackSubmissionStatus.success) {
          _whatWentWellController.clear();
          _whatCouldImproveController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Feedback submitted for ${_selectedSubject?.name ?? 'your subject'}.'
              ),
            ),
          );
          context.read<FeedbackCubit>().clearSubmissionStatus();
        } else if (feedbackState.submissionStatus ==
            FeedbackSubmissionStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                feedbackState.submissionErrorMessage ??
                    'Failed to submit feedback.',
              ),
            ),
          );
          context.read<FeedbackCubit>().clearSubmissionStatus();
        }
      },
      builder: (context, feedbackState) {
        final theme = Theme.of(context);
        final feedbackHistory = feedbackState.feedbackHistory;
        final historyLoading =
            feedbackState.status == FeedbackStatus.loading ||
            feedbackState.status == FeedbackStatus.initial;
        final isSubmitting =
            feedbackState.submissionStatus ==
            FeedbackSubmissionStatus.submitting;
        final recentItems = feedbackHistory.length > 2
            ? feedbackHistory.sublist(feedbackHistory.length - 2)
            : feedbackHistory;

        return Scaffold(
          body: StudentPageBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Feedback',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showBanner)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(15),
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(
                                    40,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  AppSpacing.hGapMd,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Anonymous Feedback',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                              ),
                                            ),
                                            Pressable(
                                              onTap: () => setState(
                                                () => _showBanner = false,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 18,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.gapXs,
                                        Text(
                                          'Your feedback helps improve the course. Instructors will see your comments but not your name.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          AppSpacing.gapXxl,

                          Text(
                            'Select Subject',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.gapSm,
                          if (_subjectsLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  AppSpacing.hGapSm,
                                  Text(
                                    'Loading subjects...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_subjectsError != null)
                            AppErrorWidget(
                              message: _subjectsError!,
                              onRetry: _loadSubjects,
                            )
                          else if (_subjects.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                'No subjects available.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<_SubjectOption>(
                                  value: _selectedSubject,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  items: _subjects
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedSubject = v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          AppSpacing.gapMd,
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final selected = _selectedSubject;
                                if (selected == null) return;
                                final cubit = context.read<FeedbackCubit>();
                                final result = await Navigator.of(context)
                                    .pushNamed<bool>(
                                      RouteNames.studentSubmitFeedback,
                                      arguments: {
                                        'subjectId': selected.id,
                                        'subjectName': selected.name,
                                      },
                                    );
                                if (result == true && mounted) {
                                  cubit.loadFeedbackHistory();
                                }
                              },
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: const Text('Open detailed form'),
                            ),
                          ),
                          AppSpacing.gapXxl,

                          Text(
                            'Rate your understanding (1-5)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Row(
                            children: List.generate(5, (i) {
                              final rating = i + 1;
                              final isSelected = rating == _selectedRating;
                              return Expanded(
                                child: Pressable(
                                  onTap: () =>
                                      setState(() => _selectedRating = rating),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: i < 4 ? 8 : 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surface,
                                      borderRadius: AppRadius.borderMd,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$rating',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimary
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                        if (rating == 1 || rating == 5) ...[
                                          AppSpacing.gapXxs,
                                          Text(
                                            rating == 1 ? 'POOR' : 'GREAT',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimary
                                                            .withAlpha(200)
                                                      : theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          AppSpacing.gapXxl,

                          Text(
                            'What went well?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.gapSm,
                          TextField(
                            controller: _whatWentWellController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Highlight effective teaching methods...',
                              hintStyle: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: Icon(
                                Icons.thumb_up_outlined,
                                color: theme.colorScheme.outlineVariant,
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          AppSpacing.gapXl,

                          Text(
                            'What could improve?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.gapSm,
                          TextField(
                            controller: _whatCouldImproveController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Suggest areas for improvement...',
                              hintStyle: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          AppSpacing.gapXxl,

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _submitFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.borderMd,
                                ),
                                elevation: 0,
                                textStyle: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isSubmitting
                                        ? 'Submitting...'
                                        : 'Submit Feedback',
                                  ),
                                  AppSpacing.hGapSm,
                                  Icon(
                                    isSubmitting
                                        ? Icons.hourglass_top_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapXxxl,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Feedback',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: _showAllFeedbackHistory,
                                child: Text(
                                  'View all',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapSm,

                          if (historyLoading)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: ShimmerList(),
                            )
                          else if (feedbackState.status == FeedbackStatus.error)
                            AppErrorWidget(
                              message:
                                  feedbackState.errorMessage ??
                                  'Unable to load feedback.',
                              onRetry: () => context
                                  .read<FeedbackCubit>()
                                  .loadFeedbackHistory(),
                            )
                          else if (recentItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: EmptyStateWidget(
                                illustration: ClipboardIllustration(),
                                icon: Icons.rate_review_rounded,
                                title: 'No feedback yet',
                                subtitle:
                                    'Your submitted feedback will appear here.',
                              ),
                            )
                          else
                            for (final fb in recentItems.reversed) ...[
                              _RecentFeedbackItem(feedback: fb),
                              AppSpacing.gapLg,
                            ],
                          AppSpacing.gapXxl,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentFeedbackItem extends StatelessWidget {
  final FeedbackModel feedback;

  const _RecentFeedbackItem({required this.feedback});

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = (feedback.status ?? 'PENDING').toUpperCase();
    final isReplied = statusLabel == 'REVIEWED';
    final statusColor = isReplied ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.subjectName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReplied
                          ? Icons.arrow_back_rounded
                          : Icons.schedule_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              Text(
                _formatDate(feedback.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.hGapMd,
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < feedback.rating
                        ? AppColors.xpGold
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              AppSpacing.hGapXs,
              Text(
                '${feedback.rating}/5 Rating',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
            AppSpacing.gapMd,
            Text(
              '"${feedback.comment}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackHistoryTile extends StatelessWidget {
  final FeedbackModel feedback;

  const _FeedbackHistoryTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMd,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withAlpha(20),
        child: Text(
          '${feedback.rating}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(feedback.subjectName),
      subtitle: Text(
        feedback.comment ?? 'No comment',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        (feedback.status ?? 'pending').toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: feedback.status == 'reviewed'
              ? AppColors.success
              : AppColors.warning,
        ),
      ),
    );
  }
}

class _SubjectOption {
  final String id;
  final String name;
  final String code;

  const _SubjectOption({
    required this.id,
    required this.name,
    required this.code,
  });
}
