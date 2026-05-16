import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_exit_helper.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/role_page_background.dart';
import '../../dashboard/screens/parent_dashboard_screen.dart';
import '../../profile_settings/screens/parent_profile_screen.dart';
import '../../profile_settings/screens/parent_settings_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _linkedChildren = [];
  int _currentIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadData() async {
    try {
      // Use the new parent-specific API endpoint
      final children = await ApiService().getMyChildren();
      if (!mounted) return;

      setState(() {
        _linkedChildren = children.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await ApiService().getNotifications();
      if (!mounted) return;
      final unread = notifications.where((n) => n['readAt'] == null).length;
      setState(() => _unreadCount = unread);
    } catch (e) {
      // Silently fail
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firstName = user?.firstName ?? 'Parent';

    final screens = <Widget>[
      _buildHomeBody(firstName),
      const ParentProfileScreen(isTabView: true),
      ParentSettingsScreen(
        isTabView: true,
        onBackToHome: () => setState(() => _currentIndex = 0),
      ),
    ];

    return PopScope(
      canPop: _currentIndex != 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          final shouldExit = await _onWillPop();
          if (shouldExit && context.mounted) {
            await AppExitHelper.exitApp();
          }
        }
      },
      child: Scaffold(
        body: RolePageBackground(
          flavor: RoleThemeFlavor.parent,
          child: IndexedStack(index: _currentIndex, children: screens),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeBody(String firstName) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                const Spacer(flex: 1),
                _buildGreeting(firstName),
                const SizedBox(height: 36),
                _buildChildCards(context),
                const Spacer(flex: 2),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile image
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: (user?.profileImageFileId != null &&
                    user!.profileImageFileId!.isNotEmpty)
                ? NetworkImage(
                    '${ApiConstants.fileBaseUrl}/api/files/${user.profileImageFileId}/download',
                  )
                : null,
            child: (user?.profileImageFileId == null ||
                    user!.profileImageFileId!.isEmpty)
                ? Icon(
                    Icons.person,
                    size: 24,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          Text(
            'TriLink',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 26,
          onPressed: () {
            Navigator.pushNamed(context, '/parent/notifications').then((_) {
              // Refresh unread count when returning
              _loadUnreadCount();
            });
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGreeting(String firstName) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${_getGreeting()}, $firstName',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _linkedChildren.isEmpty
              ? 'No children linked yet.\nAdd a child to get started.'
              : "Which child's progress would you like to\nview?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCards(BuildContext context) {
    if (_linkedChildren.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 16,
        children: _linkedChildren.map<Widget>((child) {
          // Extract student data from the link
          final student = child['student'] as Map<String, dynamic>?;
          final name =
              student?['firstName'] as String? ??
              child['firstName'] as String? ??
              child['fullName'] as String? ??
              child['name'] as String? ??
              'Child';
          final grade =
              student?['grade'] as String? ?? child['grade'] as String? ?? '';
          final studentId =
              student?['id'] as String? ??
              child['studentId'] as String? ??
              child['id'] as String? ??
              '';
          return _ChildCard(
            name: name,
            grade: grade,
            onTap: () {
              // Navigate to dashboard with selected child
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ParentDashboardScreen(initialChildId: studentId),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String grade;
  final VoidCallback onTap;

  const _ChildCard({
    required this.name,
    required this.grade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              grade,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
