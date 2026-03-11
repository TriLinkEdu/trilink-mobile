import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

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
                      'Attendance Record',
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
                      Icons.more_vert,
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
                    // Overall Attendance Card
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
                          const Text(
                            'Overall Attendance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '94%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.greenAccent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '12 Day Streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _AttendanceStat(
                                value: '45',
                                label: 'PRESENT',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                              _AttendanceStat(
                                value: '2',
                                label: 'ABSENT',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                              _AttendanceStat(
                                value: '1',
                                label: 'LATE',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subject Breakdown Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subject Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subject rows
                    _SubjectAttendanceRow(
                      icon: Icons.calculate_rounded,
                      iconColor: AppColors.primary,
                      name: 'Mathematics',
                      totalClasses: 24,
                      percentage: '92%',
                      dots: _generateDots(20, 2, 2),
                    ),
                    const SizedBox(height: 16),
                    _SubjectAttendanceRow(
                      icon: Icons.science_rounded,
                      iconColor: Colors.purple,
                      name: 'Physics',
                      totalClasses: 20,
                      percentage: '96%',
                      dots: _generateDots(19, 0, 1),
                    ),
                    const SizedBox(height: 16),
                    _SubjectAttendanceRow(
                      icon: Icons.auto_stories_rounded,
                      iconColor: Colors.orange,
                      name: 'English Literature',
                      totalClasses: 18,
                      percentage: '100%',
                      dots: _generateDots(18, 0, 0),
                    ),
                    const SizedBox(height: 24),

                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: Colors.green, label: 'Present'),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.orange, label: 'Late'),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.red, label: 'Absent'),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: Colors.grey.shade300,
                          label: 'Future',
                        ),
                      ],
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

  static List<_DotStatus> _generateDots(int present, int absent, int late) {
    final dots = <_DotStatus>[];
    for (int i = 0; i < present; i++) {
      dots.add(_DotStatus.present);
    }
    for (int i = 0; i < late; i++) {
      dots.add(_DotStatus.late);
    }
    for (int i = 0; i < absent; i++) {
      dots.add(_DotStatus.absent);
    }
    return dots;
  }
}

enum _DotStatus { present, absent, late, future }

class _AttendanceStat extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;

  const _AttendanceStat({
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendanceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final int totalClasses;
  final String percentage;
  final List<_DotStatus> dots;

  const _SubjectAttendanceRow({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.totalClasses,
    required this.percentage,
    required this.dots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Total Classes: $totalClasses',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dots
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dots.map((dot) {
              Color color;
              switch (dot) {
                case _DotStatus.present:
                  color = Colors.green;
                case _DotStatus.absent:
                  color = Colors.red;
                case _DotStatus.late:
                  color = Colors.orange;
                case _DotStatus.future:
                  color = Colors.grey.shade300;
              }
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
