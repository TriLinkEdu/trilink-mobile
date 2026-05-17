import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../repositories/student_chat_repository.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userRole;
  final String? userGrade;
  final String? profileImage;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userName,
    this.userRole,
    this.userGrade,
    this.profileImage,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _repository = sl<StudentChatRepository>();
  final _storage = sl<StorageService>();
  
  bool _isCurrentUser = false;
  bool _isBlocked = false;
  bool _canConnect = false;
  bool _loading = true;
  int _totalXp = 0;

  String _connectionStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final currentUser = await _storage.getUser();
      final currentUserId = currentUser?['id'] as String?;
      
      final profile = await _repository.fetchInteractionProfile(widget.userId);

      setState(() {
        _isCurrentUser = currentUserId == widget.userId;
        _isBlocked = profile.isBlocked;
        _connectionStatus = profile.connectionStatus;
        _totalXp = profile.totalXp;
        _canConnect = !_isCurrentUser && 
                      _connectionStatus == 'none' &&
                      widget.userRole != null && 
                      (widget.userRole == 'teacher' || widget.userRole == 'student');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _blockUser() async {
    try {
      await _repository.blockUser(widget.userId);
      if (mounted) {
        setState(() {
          _isBlocked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User blocked successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
    }
  }

  Future<void> _sendConnectionRequest() async {
    try {
      await _repository.requestConnection(widget.userId);
      if (mounted) {
        setState(() {
          _connectionStatus = 'pending_sent';
          _canConnect = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Profile Picture
                  _buildProfilePicture(theme),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    widget.userName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Role Badge
                  if (widget.userRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(theme),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.userRole!.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (widget.userGrade != null)
                          _buildInfoCard(
                            theme,
                            icon: Icons.school,
                            label: 'Grade',
                            value: widget.userGrade!,
                          ),
                        if (widget.userRole == 'student')
                          _buildInfoCard(
                            theme,
                            icon: Icons.stars,
                            label: 'Total XP',
                            value: '$_totalXp XP',
                          ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        if (!_isCurrentUser) ...[
                          if (_connectionStatus == 'accepted')
                            _buildStatusCard(theme, Icons.check_circle, 'Connected', Colors.green)
                          else if (_connectionStatus == 'pending_sent')
                            _buildStatusCard(theme, Icons.access_time, 'Connection Request Sent', Colors.orange)
                          else if (_connectionStatus == 'pending_received')
                            _buildStatusCard(theme, Icons.access_time, 'Connection Request Received', Colors.orange)
                          else if (_canConnect)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _sendConnectionRequest,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Send Connection Request'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showBlockConfirmation(context),
                              icon: const Icon(Icons.block, color: Colors.red),
                              label: const Text(
                                'Block User',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePicture(ThemeData theme) {
    if (widget.profileImage != null && widget.profileImage!.isNotEmpty) {
      final imageUrl = widget.profileImage!.startsWith('http')
          ? widget.profileImage!
          : '${ApiConstants.baseUrl}${widget.profileImage}';
      
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    // Generate avatar from initials
    final initials = _getInitials(widget.userName);
    final color = _getColorFromString(widget.userId);

    return CircleAvatar(
      radius: 60,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.userName}? They will no longer be able to message you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _blockUser();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getColorFromString(String str) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final hash = str.hashCode.abs();
    return colors[hash % colors.length];
  }

  Color _getRoleColor(ThemeData theme) {
    if (widget.userRole == 'teacher') return Colors.orange;
    if (widget.userRole == 'student') return theme.colorScheme.primary;
    return Colors.grey;
  }
}
