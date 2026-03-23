import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key});

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
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Academic Grades',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Average Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Overall Average',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '87%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Top 10% of class',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Semester Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fall Semester 2023',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View Report',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subject Cards
                    _SubjectGradeRow(
                      icon: Icons.calculate_rounded,
                      iconBgColor: Color(0xFF1A73E8),
                      name: 'Mathematics',
                      detail: '4 Tests • 2 Assignments',
                      grade: '92%',
                      change: '+4.2%',
                      isPositive: true,
                      isHighlighted: true,
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.studentSubjectGrades,
                        arguments: {
                          'subjectId': 'mathematics',
                          'subjectName': 'Mathematics',
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SubjectGradeRow(
                      icon: Icons.science_rounded,
                      iconBgColor: Color(0xFF5F6368),
                      name: 'Physics',
                      detail: '3 Tests • 1 Lab',
                      grade: '85%',
                      change: '-1.5%',
                      isPositive: false,
                      isHighlighted: false,
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.studentSubjectGrades,
                        arguments: {
                          'subjectId': 'physics',
                          'subjectName': 'Physics',
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SubjectGradeRow(
                      icon: Icons.auto_stories_rounded,
                      iconBgColor: Color(0xFF5F6368),
                      name: 'Literature',
                      detail: '2 Tests • 3 Essays',
                      grade: '88%',
                      change: '—0%',
                      isPositive: true,
                      isHighlighted: false,
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.studentSubjectGrades,
                        arguments: {
                          'subjectId': 'literature',
                          'subjectName': 'Literature',
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SubjectGradeRow(
                      icon: Icons.history_edu_rounded,
                      iconBgColor: Color(0xFF5F6368),
                      name: 'History',
                      detail: '5 Tests • 1 Project',
                      grade: '79%',
                      change: '+2.1%',
                      isPositive: true,
                      isHighlighted: false,
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.studentSubjectGrades,
                        arguments: {
                          'subjectId': 'history',
                          'subjectName': 'History',
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SubjectGradeRow(
                      icon: Icons.computer_rounded,
                      iconBgColor: Color(0xFF5F6368),
                      name: 'Computer Science',
                      detail: '3 Tests • 5 Labs',
                      grade: '95%',
                      change: '+5.5%',
                      isPositive: true,
                      isHighlighted: false,
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.studentSubjectGrades,
                        arguments: {
                          'subjectId': 'computer-science',
                          'subjectName': 'Computer Science',
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
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

class _SubjectGradeRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String name;
  final String detail;
  final String grade;
  final String change;
  final bool isPositive;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SubjectGradeRow({
    required this.icon,
    required this.iconBgColor,
    required this.name,
    required this.detail,
    required this.grade,
    required this.change,
    required this.isPositive,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withAlpha(40)
                      : iconBgColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : iconBgColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isHighlighted ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHighlighted
                            ? Colors.white.withAlpha(180)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: isHighlighted
                            ? Colors.white.withAlpha(180)
                            : isPositive
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          color: isHighlighted
                              ? Colors.white.withAlpha(180)
                              : isPositive
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
