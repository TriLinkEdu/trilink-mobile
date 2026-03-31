import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_ClassInfo> _classes = [
    _ClassInfo(
      name: 'Physics 10A',
      schedule: 'Period 2 • Mon, Wed, Fri',
      room: 'Room 302',
      studentCount: 28,
      icon: Icons.bolt,
      accentColor: AppColors.primary,
      students: [
        'Sara Mekonnen',
        'Marcus Johnson',
        'Emily Chen',
        'David Brown',
        'Alex Lee',
        'Jane Doe',
      ],
    ),
    _ClassInfo(
      name: 'Chemistry 10B',
      schedule: 'Period 3 • Tue, Thu',
      room: 'Room 115',
      studentCount: 24,
      icon: Icons.science,
      accentColor: AppColors.secondary,
      students: [
        'Liam Patel',
        'Olivia Nguyen',
        'Noah Kim',
        'Sophia Garcia',
        'Ethan Wilson',
      ],
    ),
    _ClassInfo(
      name: 'Biology 11A',
      schedule: 'Period 1 • Mon, Wed, Fri',
      room: 'Room 208',
      studentCount: 30,
      icon: Icons.biotech,
      accentColor: const Color(0xFF9C27B0),
      students: [
        'Ava Martinez',
        'Isabella Thomas',
        'Mason Clark',
        'Mia Rodriguez',
        'Lucas Hall',
        'Amelia Young',
      ],
    ),
    _ClassInfo(
      name: 'Mathematics 10C',
      schedule: 'Period 4 • Mon, Tue, Wed, Thu',
      room: 'Room 401',
      studentCount: 32,
      icon: Icons.calculate,
      accentColor: AppColors.accent,
      students: [
        'Charlotte Lewis',
        'James Walker',
        'Harper Robinson',
        'Benjamin Allen',
        'Evelyn King',
      ],
    ),
    _ClassInfo(
      name: 'English 11B',
      schedule: 'Period 5 • Tue, Thu, Fri',
      room: 'Room 104',
      studentCount: 26,
      icon: Icons.menu_book,
      accentColor: AppColors.error,
      students: [
        'Abigail Wright',
        'William Scott',
        'Ella Adams',
        'Henry Baker',
        'Scarlett Hill',
        'Daniel Green',
      ],
    ),
    _ClassInfo(
      name: 'History 12A',
      schedule: 'Period 6 • Mon, Wed',
      room: 'Room 210',
      studentCount: 22,
      icon: Icons.account_balance,
      accentColor: const Color(0xFF00897B),
      students: [
        'Victoria Turner',
        'Alexander Phillips',
        'Grace Campbell',
        'Sebastian Evans',
        'Chloe Murphy',
      ],
    ),
  ];

  List<_ClassInfo> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes
        .where(
          (c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search classes...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredClasses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cls = _filteredClasses[index];
                return _ClassCard(
                  classInfo: cls,
                  onTap: () => _showClassDetail(cls),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClassDetail(_ClassInfo cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClassDetailSheet(classInfo: cls),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final _ClassInfo classInfo;
  final VoidCallback onTap;

  const _ClassCard({required this.classInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: classInfo.accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: classInfo.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          classInfo.icon,
                          color: classInfo.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classInfo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              classInfo.schedule,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.room_outlined,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  classInfo.room,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${classInfo.studentCount} students',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassDetailSheet extends StatelessWidget {
  final _ClassInfo classInfo;

  const _ClassDetailSheet({required this.classInfo});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: classInfo.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        classInfo.icon,
                        color: classInfo.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classInfo.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${classInfo.schedule} • ${classInfo.room}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'STUDENT ROSTER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${classInfo.students.length} students',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade200, height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: classInfo.students.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade200, height: 1),
                  itemBuilder: (context, index) {
                    final student = classInfo.students[index];
                    final initials = student
                        .split(' ')
                        .map((w) => w[0])
                        .take(2)
                        .join()
                        .toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                classInfo.accentColor.withValues(alpha: 0.15),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: classInfo.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${482910 + index}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassInfo {
  final String name;
  final String schedule;
  final String room;
  final int studentCount;
  final IconData icon;
  final Color accentColor;
  final List<String> students;

  _ClassInfo({
    required this.name,
    required this.schedule,
    required this.room,
    required this.studentCount,
    required this.icon,
    required this.accentColor,
    required this.students,
  });
}
