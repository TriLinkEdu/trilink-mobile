import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'teacher_chat_conversation_screen.dart';

class TeacherNewChatScreen extends StatefulWidget {
  final String roleFilter;

  const TeacherNewChatScreen({
    super.key,
    this.roleFilter = 'student',
  });

  @override
  State<TeacherNewChatScreen> createState() => _TeacherNewChatScreenState();
}

class _TeacherNewChatScreenState extends State<TeacherNewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = false;
  bool _initiating = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await ApiService().searchUsers(
        role: widget.roleFilter,
        q: _searchQuery,
      );
      
      if (!mounted) return;
      setState(() {
        _users = users.map((u) => u as Map<String, dynamic>).toList();
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

  Future<void> _initiateChat(String userId, String userName) async {
    setState(() => _initiating = true);

    try {
      final result = await ApiService().initiateDirectChat(userId);
      
      if (!mounted) return;
      
      final conversation = result['conversation'] as Map<String, dynamic>?;
      final conversationId = conversation?['id'] as String? ?? '';
      final title = conversation?['title'] as String? ?? userName;

      if (conversationId.isEmpty) {
        throw Exception('Failed to create conversation');
      }

      setState(() => _initiating = false);

      // Navigate to conversation screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherChatConversationScreen(
            threadName: title,
            conversationId: conversationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _initiating = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getRoleLabel() {
    switch (widget.roleFilter) {
      case 'student':
        return 'Students';
      case 'parent':
        return 'Parents';
      case 'admin':
        return 'Admins';
      default:
        return 'Users';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: Text(
          'New Chat with ${_getRoleLabel()}',
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
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _loadUsers();
          },
          decoration: InputDecoration(
            hintText: 'Search by name...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade400,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadUsers();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load users',
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
                onPressed: _loadUsers,
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

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${_getRoleLabel().toLowerCase()} found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildUserTile(_users[index]),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final id = user['id'] as String? ?? '';
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final role = user['role'] as String? ?? '';
    final subject = user['subject'] as String?;
    final grade = user['grade'] as String?;
    final section = user['section'] as String?;

    String subtitle = role[0].toUpperCase() + role.substring(1);
    if (subject != null && subject.isNotEmpty) {
      subtitle += ' • $subject';
    }
    if (grade != null && grade.isNotEmpty) {
      subtitle += ' • $grade';
      if (section != null && section.isNotEmpty) {
        subtitle += '-$section';
      }
    }

    Color avatarColor;
    IconData avatarIcon;

    switch (role.toLowerCase()) {
      case 'student':
        avatarColor = AppColors.primary;
        avatarIcon = Icons.school;
        break;
      case 'parent':
        avatarColor = AppColors.secondary;
        avatarIcon = Icons.people;
        break;
      case 'admin':
        avatarColor = AppColors.accent;
        avatarIcon = Icons.admin_panel_settings;
        break;
      default:
        avatarColor = Colors.grey;
        avatarIcon = Icons.person;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: avatarColor.withValues(alpha: 0.12),
          child: Icon(avatarIcon, color: avatarColor, size: 24),
        ),
        title: Text(
          name.isNotEmpty ? name : 'Unnamed User',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _initiating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primary,
                size: 22,
              ),
        onTap: _initiating ? null : () => _initiateChat(id, name),
      ),
    );
  }
}
