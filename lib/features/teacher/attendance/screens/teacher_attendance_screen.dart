import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  String _selectedClass = 'Physics 10A - Period 2';
  final String _date = 'Oct 24, 2023';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_StudentAttendance> _students = [
    _StudentAttendance(
      name: 'Jane Doe',
      id: 'ID: 482910',
      avatarUrl: 'https://i.pravatar.cc/100?img=5',
      status: AttendanceStatus.present,
    ),
    _StudentAttendance(
      name: 'Marcus Johnson',
      id: 'ID: 482911',
      avatarUrl: 'https://i.pravatar.cc/100?img=12',
      status: AttendanceStatus.late,
    ),
    _StudentAttendance(
      name: 'Sarah Williams',
      id: 'ID: 482912',
      avatarUrl: 'https://i.pravatar.cc/100?img=9',
      status: AttendanceStatus.absent,
    ),
    _StudentAttendance(
      name: 'Alex Lee',
      id: 'ID: 482913',
      avatarUrl: '',
      status: AttendanceStatus.present,
    ),
    _StudentAttendance(
      name: 'Emily Chen',
      id: 'ID: 482914',
      avatarUrl: 'https://i.pravatar.cc/100?img=20',
      status: AttendanceStatus.present,
    ),
    _StudentAttendance(
      name: 'David Brown',
      id: 'ID: 482915',
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      status: AttendanceStatus.present,
    ),
  ];

  int get _presentCount =>
      _students.where((s) => s.status != AttendanceStatus.absent).length;

  List<_StudentAttendance> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where(
          (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _markAllPresent() {
    setState(() {
      for (var s in _students) {
        s.status = AttendanceStatus.present;
      }
    });
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
          'Daily Attendance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildClassDropdown(),
                const SizedBox(height: 12),
                _buildDateAndCount(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildListHeader(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _StudentAttendanceTile(
                  student: student,
                  onStatusChanged: (status) {
                    setState(() => student.status = status);
                  },
                );
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items:
              [
                'Physics 10A - Period 2',
                'Chemistry 10B - Period 3',
                'Biology 11A - Period 1',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedClass = val);
          },
        ),
      ),
    );
  }

  Widget _buildDateAndCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              _date,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$_presentCount/${_students.length} Present',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
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
                hintText: 'Search student...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
        const SizedBox(width: 10),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.tune, color: Colors.grey.shade600, size: 20),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'STUDENT LIST',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        GestureDetector(
          onTap: _markAllPresent,
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: AppColors.secondary),
              SizedBox(width: 4),
              Text(
                'Mark All Present',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance submitted successfully!')),
          );
        },
        icon: const Icon(Icons.send, size: 18),
        label: const Text(
          'Submit Attendance',
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

enum AttendanceStatus { present, late, absent }

class _StudentAttendance {
  final String name;
  final String id;
  final String avatarUrl;
  AttendanceStatus status;

  _StudentAttendance({
    required this.name,
    required this.id,
    required this.avatarUrl,
    required this.status,
  });
}

class _StudentAttendanceTile extends StatelessWidget {
  final _StudentAttendance student;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _StudentAttendanceTile({
    required this.student,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.id,
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
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusButton(
                label: 'Present',
                isSelected: student.status == AttendanceStatus.present,
                color: AppColors.secondary,
                onTap: () => onStatusChanged(AttendanceStatus.present),
              ),
              const SizedBox(width: 8),
              _StatusButton(
                label: 'Late',
                isSelected: student.status == AttendanceStatus.late,
                color: AppColors.accent,
                onTap: () => onStatusChanged(AttendanceStatus.late),
              ),
              const SizedBox(width: 8),
              _StatusButton(
                label: 'Absent',
                isSelected: student.status == AttendanceStatus.absent,
                color: AppColors.error,
                onTap: () => onStatusChanged(AttendanceStatus.absent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(student.avatarUrl),
      );
    }
    final initials = student.name
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

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
