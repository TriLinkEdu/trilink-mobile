import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import 'teacher_chat_conversation_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _loadingUsers = true;
  bool _creating = false;
  String? _loadError;
  String _searchQuery = '';

  List<Map<String, dynamic>> _users = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _loadError = null;
    });
    try {
      // searchUsers with no query returns up to 20 relevant users
      final results = await ApiService().searchUsers(q: _searchQuery);
      if (!mounted) return;
      setState(() {
        _users = results.cast<Map<String, dynamic>>();
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingUsers = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'
          .toLowerCase();
      return name.contains(q);
    }).toList();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final result = await ApiService().createConversation({
        'type': 'group',
        'title': name,
        'memberIds': _selectedIds.toList(),
        'parentVisible': false,
      });

      if (!mounted) return;

      final conversationId = result['id'] as String? ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate directly into the new group conversation
      if (conversationId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherChatConversationScreen(
              threadName: name,
              conversationId: conversationId,
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    }
  }

  String _initials(Map<String, dynamic> user) {
    final f = (user['firstName'] as String? ?? '');
    final l = (user['lastName'] as String? ?? '');
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  Color _roleColor(ThemeData theme, String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return theme.colorScheme.primary;
      case 'parent':
        return theme.colorScheme.secondary;
      case 'admin':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Group',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name field
                  Text(
                    'Group Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Biology 101 – Period 2',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Members header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (_selectedIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedIds.length} selected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _loadUsers();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadUsers();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User list
                  if (_loadingUsers)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_loadError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Failed to load users',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._filtered.map((u) => _buildUserTile(u)),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final id = user['id'] as String? ?? '';
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final role = user['role'] as String? ?? '';
    final subject = user['subject'] as String?;
    final grade = user['grade'] as String?;
    final section = user['section'] as String?;
    final selected = _selectedIds.contains(id);
    final color = _roleColor(theme, role);

    String subtitle = role.isNotEmpty
        ? role[0].toUpperCase() + role.substring(1)
        : '';
    if (subject != null && subject.isNotEmpty) subtitle += ' • $subject';
    if (grade != null && grade.isNotEmpty) {
      subtitle += ' • $grade';
      if (section != null && section.isNotEmpty) subtitle += '-$section';
    }

    return GestureDetector(
      onTap: () {
        if (id.isEmpty) return;
        setState(() {
          if (selected) {
            _selectedIds.remove(id);
          } else {
            _selectedIds.add(id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.16),
              child: Text(
                _initials(user),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Unnamed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: id.isEmpty
                  ? null
                  : (_) {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      });
                    },
              activeColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _creating ? null : _createGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: _creating
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Text(
                  'Create Group',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
