import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WeeklyReportScreen extends StatefulWidget {
  final String childName;

  const WeeklyReportScreen({super.key, required this.childName});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  int _weekOffset = 0;

  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Math',
      'icon': Icons.calculate,
      'color': AppColors.primary,
      'grade': '91%',
      'attendance': '5/5',
      'note': 'Excellent work on quadratic equations. Keep practicing word problems.',
    },
    {
      'name': 'Science',
      'icon': Icons.science,
      'color': AppColors.secondary,
      'grade': '85%',
      'attendance': '4/5',
      'note': 'Missed lab on Wednesday. Please review the experiment notes.',
    },
    {
      'name': 'English',
      'icon': Icons.menu_book,
      'color': Colors.purple,
      'grade': '88%',
      'attendance': '5/5',
      'note': 'Great essay submission. Grammar has improved significantly.',
    },
    {
      'name': 'Arabic',
      'icon': Icons.translate,
      'color': Colors.orange,
      'grade': '82%',
      'attendance': '5/5',
      'note': 'Needs more practice with formal writing structures.',
    },
    {
      'name': 'Computer Science',
      'icon': Icons.computer,
      'color': AppColors.error,
      'grade': '94%',
      'attendance': '5/5',
      'note': 'Outstanding performance in the Python project. Very creative solution.',
    },
  ];

  final List<Map<String, String>> _teacherNotes = [
    {
      'teacher': 'Mr. Hassan',
      'subject': 'Math',
      'note':
          'Ahmed has shown great improvement this week. His problem-solving skills are getting stronger.',
    },
    {
      'teacher': 'Ms. Fatima',
      'subject': 'Science',
      'note':
          'Please ensure homework is submitted on time. The upcoming test covers chapters 5-7.',
    },
    {
      'teacher': 'Dr. Khalid',
      'subject': 'Computer Science',
      'note':
          'Exceptional work on the group project. Ahmed took a leadership role and delivered quality code.',
    },
  ];

  final Set<int> _expandedSubjects = {0};

  String get _weekLabel {
    final base = DateTime(2026, 3, 10);
    final start = base.add(Duration(days: _weekOffset * 7));
    final end = start.add(const Duration(days: 6));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Report',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.childName,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeekSelector(),
                  const SizedBox(height: 20),
                  _buildSummaryStats(),
                  const SizedBox(height: 24),
                  _buildSubjectBreakdown(),
                  const SizedBox(height: 24),
                  _buildTeacherNotes(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _weekOffset--),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textPrimary),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _weekLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _weekOffset++),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.chevron_right, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle_outline,
              iconColor: AppColors.secondary,
              label: 'Attendance',
              value: '5/5 days',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              icon: Icons.trending_up,
              iconColor: AppColors.primary,
              label: 'Avg Grade',
              value: '87%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              icon: Icons.assignment_turned_in_outlined,
              iconColor: Colors.orange,
              label: 'Assignments',
              value: '8/10',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(_subjects.length, (index) {
            final subject = _subjects[index];
            final isExpanded = _expandedSubjects.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedSubjects.remove(index);
                    } else {
                      _expandedSubjects.add(index);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpanded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (subject['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              subject['icon'] as IconData,
                              color: subject['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subject['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            subject['grade'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_available, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Attendance: ${subject['attendance']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.comment_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      subject['note'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherNotes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teacher Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ..._teacherNotes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note['teacher']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                note['subject']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note['note']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download, size: 18),
        label: const Text(
          'Download Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
