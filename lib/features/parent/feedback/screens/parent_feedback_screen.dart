import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ParentFeedbackScreen extends StatefulWidget {
  const ParentFeedbackScreen({super.key});

  @override
  State<ParentFeedbackScreen> createState() => _ParentFeedbackScreenState();
}

class _ParentFeedbackScreenState extends State<ParentFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _feedbackController = TextEditingController();
  String _selectedTeacher = 'Mr. Ahmed Hassan – Mathematics';

  final List<String> _teacherOptions = [
    'Mr. Ahmed Hassan – Mathematics',
    'Ms. Fatima Ali – Science',
    'Mrs. Sarah Johnson – English',
    'Mr. Khalid Omar – Arabic',
    'Dr. Nour Haddad – Computer Science',
  ];

  final List<_TeacherComment> _teacherComments = [
    _TeacherComment(
      teacher: 'Mr. Ahmed Hassan',
      subject: 'Mathematics',
      date: 'Mar 22, 2026',
      comment:
          'Omar has shown excellent progress in algebra this term. His homework submissions are '
          'consistent and well-organized. I encourage him to participate more in class discussions.',
      sentiment: _Sentiment.positive,
    ),
    _TeacherComment(
      teacher: 'Ms. Fatima Ali',
      subject: 'Science',
      date: 'Mar 20, 2026',
      comment:
          'Layla did well on the recent biology quiz. She could benefit from reviewing the '
          'chemistry section more thoroughly before the mid-term exam.',
      sentiment: _Sentiment.neutral,
    ),
    _TeacherComment(
      teacher: 'Mrs. Sarah Johnson',
      subject: 'English',
      date: 'Mar 18, 2026',
      comment:
          'Omar needs to improve his essay writing skills. The last assignment was submitted late '
          'and had several grammatical errors. I recommend setting up a writing practice routine.',
      sentiment: _Sentiment.needsImprovement,
    ),
    _TeacherComment(
      teacher: 'Mr. Khalid Omar',
      subject: 'Arabic',
      date: 'Mar 16, 2026',
      comment:
          'Layla is performing very well in Arabic. Her reading comprehension is above average '
          'and she actively participates in class. Keep up the excellent work!',
      sentiment: _Sentiment.positive,
    ),
  ];

  final List<_SentFeedback> _sentFeedback = [
    _SentFeedback(
      recipient: 'Mr. Ahmed Hassan – Mathematics',
      date: 'Mar 21, 2026',
      message:
          'Thank you for the update on Omar\'s progress. We will continue to encourage his studies at home.',
      status: 'Read',
    ),
    _SentFeedback(
      recipient: 'Mrs. Sarah Johnson – English',
      date: 'Mar 19, 2026',
      message:
          'We appreciate the feedback. Omar will be working on improving his writing. Could you recommend any resources?',
      status: 'Replied',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _sendFeedback() {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _sentFeedback.insert(
        0,
        _SentFeedback(
          recipient: _selectedTeacher,
          date: 'Mar 23, 2026',
          message: _feedbackController.text.trim(),
          status: 'Sent',
        ),
      );
      _feedbackController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback sent successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feedback & Comments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Teacher Comments'),
            Tab(text: 'My Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeacherCommentsTab(),
          _buildMyFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildTeacherCommentsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _teacherComments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = _teacherComments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildCommentCard(_TeacherComment comment) {
    return Container(
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
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  comment.teacher.split(' ').map((p) => p[0]).take(2).join(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.teacher,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      comment.subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSentimentIcon(comment.sentiment),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.comment,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            comment.date,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentIcon(_Sentiment sentiment) {
    IconData icon;
    Color color;
    String label;

    switch (sentiment) {
      case _Sentiment.positive:
        icon = Icons.sentiment_satisfied_alt;
        color = AppColors.secondary;
        label = 'Positive';
      case _Sentiment.neutral:
        icon = Icons.sentiment_neutral;
        color = AppColors.accent;
        label = 'Neutral';
      case _Sentiment.needsImprovement:
        icon = Icons.trending_up;
        color = const Color(0xFFF57C00);
        label = 'Improve';
    }

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildMyFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sentFeedback.isNotEmpty) ...[
            const Text(
              'Sent Feedback',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._sentFeedback.map(_buildSentFeedbackCard),
            const SizedBox(height: 24),
          ],
          _buildNewFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildSentFeedbackCard(_SentFeedback feedback) {
    Color statusColor;
    switch (feedback.status) {
      case 'Sent':
        statusColor = AppColors.textSecondary;
      case 'Read':
        statusColor = AppColors.primary;
      case 'Replied':
        statusColor = AppColors.secondary;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.recipient,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  feedback.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback.date,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNewFeedbackSection() {
    return Container(
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
          const Text(
            'New Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedTeacher,
            decoration: InputDecoration(
              labelText: 'Select Teacher / Subject',
              labelStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _teacherOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedTeacher = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Write your feedback or question...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
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
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendFeedback,
              icon: const Icon(Icons.send, size: 18),
              label: const Text(
                'Send Feedback',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Sentiment { positive, neutral, needsImprovement }

class _TeacherComment {
  final String teacher;
  final String subject;
  final String date;
  final String comment;
  final _Sentiment sentiment;

  _TeacherComment({
    required this.teacher,
    required this.subject,
    required this.date,
    required this.comment,
    required this.sentiment,
  });
}

class _SentFeedback {
  final String recipient;
  final String date;
  final String message;
  final String status;

  _SentFeedback({
    required this.recipient,
    required this.date,
    required this.message,
    required this.status,
  });
}
