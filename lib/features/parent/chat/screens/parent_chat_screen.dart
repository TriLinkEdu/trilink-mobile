import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import 'parent_message_view_screen.dart';

class ParentChatScreen extends StatefulWidget {
  const ParentChatScreen({super.key});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  
  List<_ContactUser> _adminUsers = [];
  List<_ContactUser> _teacherUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Search for admin and teacher users
      final users = await ApiService().searchUsers();
      
      if (!mounted) return;
      
      final List<_ContactUser> admins = [];
      final List<_ContactUser> teachers = [];
      
      for (final user in users) {
        final role = user['role'] as String?;
        if (role == 'admin') {
          admins.add(_ContactUser.fromJson(user));
        } else if (role == 'teacher') {
          teachers.add(_ContactUser.fromJson(user));
        }
      }
      
      setState(() {
        _adminUsers = admins;
        _teacherUsers = teachers;
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

  Future<void> _startConversation(_ContactUser user) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Initiate conversation
      final response = await ApiService().initiateConversation(user.id);
      final conversation = response['conversation'] as Map<String, dynamic>;
      final conversationId = conversation['id'] as String;

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Navigate to message view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParentMessageViewScreen(
            conversationId: conversationId,
            teacherName: user.fullName,
            subject: user.role == 'admin' ? 'Administrator' : user.subject ?? 'Teacher',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _buildTabView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: theme.colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: AppColors.primary),
          insets: EdgeInsets.symmetric(horizontal: 24),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Admin'),
                if (_adminUsers.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_adminUsers.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Teachers'),
                if (_teacherUsers.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_teacherUsers.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAdminTab(),
        _buildTeachersTab(),
      ],
    );
  }

  Widget _buildAdminTab() {
    if (_adminUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No administrators available',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _adminUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ContactTile(
        user: _adminUsers[index],
        onTap: () => _startConversation(_adminUsers[index]),
      ),
    );
  }

  Widget _buildTeachersTab() {
    if (_teacherUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No teachers available',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _teacherUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ContactTile(
        user: _teacherUsers[index],
        onTap: () => _startConversation(_teacherUsers[index]),
      ),
    );
  }
}

class _ContactUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? subject;
  final String? department;
  final String? profileImageFileId;
  final String? profileImagePath;

  _ContactUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.subject,
    this.department,
    this.profileImageFileId,
    this.profileImagePath,
  });

  String get fullName => '$firstName $lastName'.trim();
  
  String get displaySubject {
    if (role == 'admin') return 'Administrator';
    return subject ?? 'Teacher';
  }

  factory _ContactUser.fromJson(Map<String, dynamic> json) {
    // Helper function to handle "null" strings from API
    String? parseNullableString(dynamic value) {
      if (value == null || value == 'null') return null;
      final str = value as String?;
      return str?.trim().isEmpty == true ? null : str?.trim();
    }

    return _ContactUser(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      subject: parseNullableString(json['subject']),
      department: parseNullableString(json['department']),
      profileImageFileId: parseNullableString(json['profileImageFileId']),
      profileImagePath: parseNullableString(json['profileImagePath']),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final _ContactUser user;
  final VoidCallback onTap;

  const _ContactTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.displaySubject,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (user.department != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            user.department!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<Map<String, String>?>(
      future: _getAuthHeaders(),
      builder: (context, snapshot) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: (user.profileImagePath != null && 
                           user.profileImagePath!.isNotEmpty && 
                           snapshot.hasData)
              ? NetworkImage(
                  '${ApiConstants.fileBaseUrl}${user.profileImagePath}',
                  headers: snapshot.data,
                )
              : null,
          child: (user.profileImagePath == null || user.profileImagePath!.isEmpty)
              ? Text(
                  _getInitials(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        );
      },
    );
  }

  String _getInitials() {
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await StorageService().accessToken;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }
}
