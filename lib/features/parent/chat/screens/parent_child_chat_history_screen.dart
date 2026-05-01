import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'parent_child_conversation_view_screen.dart';

class ParentChildChatHistoryScreen extends StatefulWidget {
  final String studentId;
  final String childName;

  const ParentChildChatHistoryScreen({
    super.key,
    required this.studentId,
    required this.childName,
  });

  @override
  State<ParentChildChatHistoryScreen> createState() =>
      _ParentChildChatHistoryScreenState();
}

class _ParentChildChatHistoryScreenState
    extends State<ParentChildChatHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];
  String _typeFilter = 'all'; // all | direct | group

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await ApiService().getChildConversations(widget.studentId);

      if (!mounted) return;
      setState(() {
        _conversations = data.cast<Map<String, dynamic>>();
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
              'Chat History',
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

    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _typeFilter == 'all'
        ? _conversations
        : _conversations
            .where((c) =>
                (c['type'] as String? ?? '').toLowerCase() == _typeFilter)
            .toList();

    final directCount = _conversations
        .where((c) => (c['type'] as String? ?? '') == 'direct')
        .length;
    final groupCount = _conversations
        .where((c) => (c['type'] as String? ?? '') == 'group')
        .length;

    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              _buildFilterChip(
                'All',
                'all',
                _conversations.length,
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Direct',
                'direct',
                directCount,
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Groups',
                'group',
                groupCount,
                AppColors.secondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_typeFilter == 'all' ? '' : _typeFilter} conversations',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _buildConversationCard(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
      String label, String value, int count, Color color) {
    final selected = _typeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final id = conversation['id'] as String? ?? '';
    final title = conversation['title'] as String? ?? 'Conversation';
    final type = conversation['type'] as String? ?? 'direct';
    final updatedAt = conversation['updatedAt'] as String? ?? '';

    IconData typeIcon;
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'group':
        typeIcon = Icons.group;
        typeColor = AppColors.secondary;
        break;
      case 'direct':
        typeIcon = Icons.person;
        typeColor = AppColors.primary;
        break;
      default:
        typeIcon = Icons.chat_bubble_outline;
        typeColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentChildConversationViewScreen(
              studentId: widget.studentId,
              conversationId: id,
              conversationTitle: title,
              childName: widget.childName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type[0].toUpperCase() + type.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (updatedAt.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
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
              onPressed: _loadConversations,
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
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No conversations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your child has no conversations yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(d);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[d.month - 1]} ${d.day}';
      }
    } catch (_) {
      return iso;
    }
  }
}
