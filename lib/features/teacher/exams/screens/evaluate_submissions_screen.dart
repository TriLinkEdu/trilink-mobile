import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EvaluateSubmissionsScreen extends StatefulWidget {
  final String examId;

  const EvaluateSubmissionsScreen({super.key, required this.examId});

  @override
  State<EvaluateSubmissionsScreen> createState() =>
      _EvaluateSubmissionsScreenState();
}

class _EvaluateSubmissionsScreenState extends State<EvaluateSubmissionsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Graded'];

  final List<_StudentSubmission> _submissions = [
    _StudentSubmission(
      name: 'Sarah Jenkins',
      studentId: 'STU-1024',
      avatarUrl: 'https://i.pravatar.cc/100?img=9',
      submissionTime: '10:42 AM',
      isGraded: true,
      score: 92,
    ),
    _StudentSubmission(
      name: 'Mike Ross',
      studentId: 'STU-1031',
      avatarUrl: 'https://i.pravatar.cc/100?img=33',
      submissionTime: '10:45 AM',
      isGraded: false,
      score: null,
    ),
    _StudentSubmission(
      name: 'Jessica Pearson',
      studentId: 'STU-1018',
      avatarUrl: 'https://i.pravatar.cc/100?img=45',
      submissionTime: '10:38 AM',
      isGraded: true,
      score: 78,
    ),
    _StudentSubmission(
      name: 'James Liu',
      studentId: 'STU-1042',
      avatarUrl: '',
      submissionTime: '10:50 AM',
      isGraded: true,
      score: 85,
    ),
    _StudentSubmission(
      name: 'Amira Hassan',
      studentId: 'STU-1055',
      avatarUrl: 'https://i.pravatar.cc/100?img=25',
      submissionTime: '10:48 AM',
      isGraded: false,
      score: null,
    ),
    _StudentSubmission(
      name: 'Robert Zane',
      studentId: 'STU-1009',
      avatarUrl: 'https://i.pravatar.cc/100?img=51',
      submissionTime: '10:35 AM',
      isGraded: false,
      score: null,
    ),
  ];

  int get _totalSubmitted => _submissions.length;
  int get _totalGraded => _submissions.where((s) => s.isGraded).length;
  int get _totalPending => _submissions.where((s) => !s.isGraded).length;

  List<_StudentSubmission> get _filteredSubmissions {
    switch (_selectedFilter) {
      case 'Pending':
        return _submissions.where((s) => !s.isGraded).toList();
      case 'Graded':
        return _submissions.where((s) => s.isGraded).toList();
      default:
        return _submissions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exam ${widget.examId}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(child: _buildSubmissionList()),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              value: '$_totalSubmitted',
              label: 'Submitted',
              color: AppColors.primary,
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.divider,
            ),
            _SummaryItem(
              value: '$_totalGraded',
              label: 'Graded',
              color: AppColors.secondary,
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.divider,
            ),
            _SummaryItem(
              value: '$_totalPending',
              label: 'Pending',
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmissionList() {
    final submissions = _filteredSubmissions;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return _SubmissionCard(
          submission: submission,
          onGrade: () => _showGradeSheet(submission),
        );
      },
    );
  }

  void _showGradeSheet(_StudentSubmission submission) {
    final scoreController = TextEditingController();
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Grade ${submission.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                submission.studentId,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              const Text(
                'Score (out of 100)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter score...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Feedback',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter feedback for the student...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final score = int.tryParse(scoreController.text);
                    if (score == null || score < 0 || score > 100) return;
                    setState(() {
                      final idx = _submissions.indexOf(submission);
                      if (idx != -1) {
                        _submissions[idx] = _StudentSubmission(
                          name: submission.name,
                          studentId: submission.studentId,
                          avatarUrl: submission.avatarUrl,
                          submissionTime: submission.submissionTime,
                          isGraded: true,
                          score: score,
                        );
                      }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${submission.name} graded: $score/100',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit Grade',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentSubmission {
  final String name;
  final String studentId;
  final String avatarUrl;
  final String submissionTime;
  final bool isGraded;
  final int? score;

  _StudentSubmission({
    required this.name,
    required this.studentId,
    required this.avatarUrl,
    required this.submissionTime,
    required this.isGraded,
    required this.score,
  });
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final _StudentSubmission submission;
  final VoidCallback onGrade;

  const _SubmissionCard({
    required this.submission,
    required this.onGrade,
  });

  Color get _scoreColor {
    if (submission.score == null) return Colors.grey;
    if (submission.score! >= 85) return AppColors.secondary;
    if (submission.score! >= 60) return AppColors.accent;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      submission.studentId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      submission.submissionTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: submission.isGraded
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    submission.isGraded ? 'Graded' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: submission.isGraded
                          ? AppColors.secondary
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (submission.isGraded && submission.score != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _scoreColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: _scoreColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${submission.score}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _scoreColor,
                  ),
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onGrade,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Grade',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (submission.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(submission.avatarUrl),
      );
    }
    final initials = submission.name
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
