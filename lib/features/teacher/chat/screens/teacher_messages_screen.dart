import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'create_group_screen.dart';
import 'teacher_chat_conversation_screen.dart';
import 'teacher_new_chat_screen.dart';

class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await ApiService().getConversations();
      if (!mounted) return;
      setState(() {
        _conversations =
            conversations.map((c) => c as Map<String, dynamic>).toList();
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

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getConversationsByType(String type) {
    final filtered = _filteredConversations;
    
    switch (type) {
      case 'student':
        // Direct chats with students
        return filtered.where((c) {
          final convType = c['type'] as String? ?? '';
          if (convType != 'direct') return false;
          
          // Check if conversation involves a student
          // This is a simplified check - you may need to enhance based on your data structure
          final title = (c['title'] as String? ?? '').toLowerCase();
          return !title.contains('parent') && !title.contains('admin');
        }).toList();
        
      case 'parent':
        // Direct chats with parents
        return filtered.where((c) {
          final convType = c['type'] as String? ?? '';
          if (convType != 'direct') return false;
          
          final title = (c['title'] as String? ?? '').toLowerCase();
          return title.contains('parent');
        }).toList();
        
      case 'admin':
        // Direct chats with admins
        return filtered.where((c) {
          final convType = c['type'] as String? ?? '';
          if (convType != 'direct') return false;
          
          final title = (c['title'] as String? ?? '').toLowerCase();
          return title.contains('admin');
        }).toList();
        
      case 'group':
        // Group conversations
        return filtered.where((c) {
          final convType = c['type'] as String? ?? '';
          return convType == 'group';
        }).toList();
        
      default:
        return [];
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatList('student'),
                  _buildChatList('parent'),
                  _buildChatList('admin'),
                  _buildChatList('group'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
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
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          _buildTab(Icons.school_outlined, 'Students'),
          _buildTab(Icons.people_outline, 'Parents'),
          _buildTab(Icons.admin_panel_settings_outlined, 'Admin'),
          _buildTab(Icons.group_outlined, 'Groups'),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildChatList(String type) {
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
                'Failed to load conversations',
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
                onPressed: _loadData,
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

    final chats = _getConversationsByType(type);

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'group' ? Icons.group_outlined : Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'group'
                  ? 'No groups yet'
                  : 'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'group'
                  ? 'Create a group to start chatting'
                  : 'Start a new conversation',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => _buildChatTile(chats[index]),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> conversation) {
    final id = conversation['id'] as String? ?? '';
    final title = conversation['title'] as String? ?? 'Unnamed';
    final type = conversation['type'] as String? ?? 'direct';
    final updatedAt = conversation['updatedAt'] as String?;
    
    // You can enhance this to show last message from the conversation
    final subtitle = type == 'group' ? 'Group chat' : 'Tap to open';

    IconData icon;
    Color iconColor;

    if (type == 'group') {
      icon = Icons.group;
      iconColor = AppColors.accent;
    } else {
      icon = Icons.person;
      iconColor = AppColors.primary;
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
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeAgo(updatedAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherChatConversationScreen(
                threadName: title,
                conversationId: id,
              ),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildFAB() {
    final currentTab = _tabController.index;
    
    return FloatingActionButton.extended(
      onPressed: () async {
        if (currentTab == 3) {
          // Groups tab - show create group screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateGroupScreen(),
            ),
          );
        } else {
          // Other tabs - show new chat screen with role filter
          String role;
          switch (currentTab) {
            case 0:
              role = 'student';
              break;
            case 1:
              role = 'parent';
              break;
            case 2:
              role = 'admin';
              break;
            default:
              role = 'student';
          }
          
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherNewChatScreen(roleFilter: role),
            ),
          );
        }
        _loadData();
      },
      backgroundColor: AppColors.primary,
      icon: Icon(
        currentTab == 3 ? Icons.group_add : Icons.chat_bubble_outline,
        color: Colors.white,
      ),
      label: Text(
        currentTab == 3 ? 'New Group' : 'New Chat',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
