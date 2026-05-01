import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../chat/screens/parent_message_view_screen.dart';

class ParentTeachersScreen extends StatefulWidget {
  final String studentId;
  final String childName;

  const ParentTeachersScreen({
    super.key,
    required this.studentId,
    required this.childName,
  });

  @override
  State<ParentTeachersScreen> createState() => _ParentTeachersScreenState();
}

class _ParentTeachersScreenState extends State<ParentTeachersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _teachers = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService().getStudentTeachers(widget.studentId);
      final teachersData = data['teachers'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _teachers = teachersData.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teachers',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.childName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_teachers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTeachers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _teachers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildTeacherCard(_teachers[index], index),
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher, int index) {
    final firstName = teacher['firstName'] as String? ?? '';
    final lastName = teacher['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    final subjects = (teacher['subjects'] as List<dynamic>? ?? [])
        .map((s) => s.toString())
        .toList();
    final department = teacher['department'] as String? ?? '';
    final email = teacher['email'] as String? ?? '';
    final phone = teacher['phone'] as String? ?? '';
    final teacherId = teacher['id'] as String? ?? '';
    final isExpanded = _expandedIndex == index;

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
      const Color(0xFF00BFA5),
      const Color(0xFFE91E63),
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row — always visible
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subjects.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subjects.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (department.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              department,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expandable details
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade100),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject chips
                        if (subjects.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: subjects
                                      .map((s) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              s,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: Colors.grey.shade100),
                          const SizedBox(height: 10),
                        ],
                        // Email
                        if (email.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        // Phone
                        if (phone.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Send Message button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openTeacherChat(
                              teacherId: teacherId,
                              teacherName: fullName,
                              subject:
                                  subjects.isNotEmpty ? subjects.first : '',
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Send Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load teachers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTeachers,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No teachers found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No teachers are assigned to this student.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _openTeacherChat({
    required String teacherId,
    required String teacherName,
    required String subject,
  }) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService().initiateConversation(teacherId);
      final conversation = response['conversation'] as Map<String, dynamic>;
      final conversationId = conversation['id'] as String;

      if (!mounted) return;
      Navigator.pop(context); // close loader

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParentMessageViewScreen(
            conversationId: conversationId,
            teacherName: teacherName,
            subject: subject,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
