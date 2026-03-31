import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/feedback_cubit.dart';
import '../models/feedback_model.dart';
import '../repositories/student_feedback_repository.dart';
import 'submit_feedback_screen.dart';

class StudentFeedbackScreen extends StatelessWidget {
  const StudentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FeedbackCubit(sl<StudentFeedbackRepository>())..loadFeedbackHistory(),
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
  String _selectedSubject = 'Mathematics 101';
  bool _isSubmitting = false;
  bool _showBanner = true;
  final _whatWentWellController = TextEditingController();
  final _whatCouldImproveController = TextEditingController();

  final List<String> _subjects = [
    'Mathematics 101',
    'Physics',
    'Literature',
    'History',
    'Computer Science',
  ];

  @override
  void dispose() {
    _whatWentWellController.dispose();
    _whatCouldImproveController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final positive = _whatWentWellController.text.trim();
    final improvement = _whatCouldImproveController.text.trim();

    if (positive.isEmpty && improvement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one feedback comment.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final comment = [
        if (positive.isNotEmpty) 'What went well: $positive',
        if (improvement.isNotEmpty) 'Could improve: $improvement',
      ].join('\n');

      await sl<StudentFeedbackRepository>().submitFeedback(
        subjectId: _selectedSubject.toLowerCase().replaceAll(' ', '_'),
        subjectName: _selectedSubject,
        rating: _selectedRating,
        comment: comment,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _whatWentWellController.clear();
      _whatCouldImproveController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted for $_selectedSubject.')),
      );

      context.read<FeedbackCubit>().loadFeedbackHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback.')),
      );
    }
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
                    style: TextStyle(
                      fontSize: 18,
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
                  ? Center(
                      child: Text(
                        'No feedback submitted yet.',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: feedbackHistory.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final fb = feedbackHistory[index];
                        return _FeedbackHistoryTile(feedback: fb);
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
    return BlocBuilder<FeedbackCubit, FeedbackState>(
      builder: (context, feedbackState) {
        final theme = Theme.of(context);
        final feedbackHistory = feedbackState.feedbackHistory;
        final historyLoading = feedbackState.status == FeedbackStatus.loading ||
            feedbackState.status == FeedbackStatus.initial;
        final recentItems = feedbackHistory.length > 2
            ? feedbackHistory.sublist(feedbackHistory.length - 2)
            : feedbackHistory;

        return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
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
                      style: TextStyle(
                        fontSize: 18,
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _showBanner = false),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your feedback helps improve the course. Instructors will see your comments but not your name.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),

                    Text(
                      'Select Subject',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          items: _subjects
                              .map(
                                (s) => DropdownMenuItem(
                                    value: s, child: Text(s)),
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final cubit = context.read<FeedbackCubit>();
                          final result =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => SubmitFeedbackScreen(
                                subjectId: _selectedSubject
                                    .toLowerCase()
                                    .replaceAll(' ', '_'),
                                subjectName: _selectedSubject,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            cubit.loadFeedbackHistory();
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded,
                            size: 16),
                        label: const Text('Open detailed form'),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'Rate your understanding (1-5)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (i) {
                        final rating = i + 1;
                        final isSelected = rating == _selectedRating;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedRating = rating),
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: i < 4 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(10),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (rating == 1 ||
                                      rating == 5) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      rating == 1
                                          ? 'POOR'
                                          : 'GREAT',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                                .withAlpha(200)
                                            : theme.colorScheme
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
                    const SizedBox(height: 22),

                    Text(
                      'What went well?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _whatWentWellController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Highlight effective teaching methods...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        suffixIcon: Icon(
                          Icons.thumb_up_outlined,
                          color: theme.colorScheme.outlineVariant,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'What could improve?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _whatCouldImproveController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Suggest areas for improvement...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(_isSubmitting
                                ? 'Submitting...'
                                : 'Submit Feedback'),
                            const SizedBox(width: 6),
                            Icon(
                              _isSubmitting
                                  ? Icons.hourglass_top_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: _showAllFeedbackHistory,
                          child: Text(
                            'View all',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (historyLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (feedbackState.status == FeedbackStatus.error)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                feedbackState.errorMessage ?? '',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<FeedbackCubit>()
                                    .loadFeedbackHistory(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (recentItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No feedback submitted yet.',
                            style: TextStyle(
                                color: theme
                                    .colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      for (final fb
                          in recentItems.reversed) ...[
                        _RecentFeedbackItem(feedback: fb),
                        const SizedBox(height: 14),
                      ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = (feedback.status ?? 'PENDING').toUpperCase();
    final isReplied = statusLabel == 'REVIEWED';
    final statusColor = isReplied ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.subjectName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
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
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatDate(feedback.createdAt),
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < feedback.rating
                        ? Colors.amber
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${feedback.rating}/5 Rating',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          if (feedback.comment != null &&
              feedback.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${feedback.comment}"',
              style: TextStyle(
                fontSize: 12,
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
        borderRadius: BorderRadius.circular(12),
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: feedback.status == 'reviewed'
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  }
}
