import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows detailed grade breakdown for a specific subject.
class SubjectGradesScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const SubjectGradesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subjectName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
                    // Current Average Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CURRENT AVERAGE',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(180),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '92',
                                style: TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(180),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Grade A',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatBox(label: 'Highest Score', value: '98%'),
                              _StatBox(label: 'Lowest Score', value: '74%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Grade Distribution
                    const Text(
                      'Grade Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _GradeBar(grade: 'A', count: 4, maxCount: 4),
                    const SizedBox(height: 8),
                    const _GradeBar(grade: 'B', count: 4, maxCount: 4),
                    const SizedBox(height: 8),
                    const _GradeBar(grade: 'C', count: 2, maxCount: 4),
                    const SizedBox(height: 8),
                    const _GradeBar(grade: 'D', count: 1, maxCount: 4),
                    const SizedBox(height: 28),

                    // Assessments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assessments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Sort by Date',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.quiz_rounded,
                      title: 'Quiz 4: Algebra II',
                      date: 'Oct 28, 2023',
                      score: '98%',
                      grade: 'A+',
                      gradeColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.assignment_rounded,
                      title: 'Midterm Exam',
                      date: 'Oct 24, 2023',
                      score: '94%',
                      grade: 'A',
                      gradeColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.quiz_rounded,
                      title: 'Quiz 3: Forces',
                      date: 'Oct 15, 2023',
                      score: '88%',
                      grade: 'B+',
                      gradeColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.science_rounded,
                      title: 'Lab Report: Motion',
                      date: 'Oct 10, 2023',
                      score: '92%',
                      grade: 'A',
                      gradeColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.quiz_rounded,
                      title: 'Quiz 2: Geometry',
                      date: 'Sep 28, 2023',
                      score: '74%',
                      grade: 'C',
                      gradeColor: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    const _AssessmentRow(
                      icon: Icons.quiz_rounded,
                      title: 'Quiz 1: Basics',
                      date: 'Sep 15, 2023',
                      score: '100%',
                      grade: 'A+',
                      gradeColor: Colors.green,
                    ),
                    const SizedBox(height: 24),

                    // Download button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Download Report PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withAlpha(180),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GradeBar extends StatelessWidget {
  final String grade;
  final int count;
  final int maxCount;

  const _GradeBar({
    required this.grade,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            grade,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: count / maxCount,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String score;
  final String grade;
  final Color gradeColor;

  const _AssessmentRow({
    required this.icon,
    required this.title,
    required this.date,
    required this.score,
    required this.grade,
    required this.gradeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
