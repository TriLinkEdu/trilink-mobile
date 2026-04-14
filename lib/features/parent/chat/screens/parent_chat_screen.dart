import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'parent_message_view_screen.dart';

class ParentChatScreen extends StatefulWidget {
  const ParentChatScreen({super.key});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
  bool _loading = true;
  String? _error;
  List<_MessageThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() { _loading = true; _error = null; });
      final conversations = await ApiService().getConversations();
      if (!mounted) return;
      setState(() {
        _threads = conversations.map<_MessageThread>((c) {
          return _MessageThread(
            id: c['id'] as String? ?? '',
            name: c['participantName'] as String? ??
                c['name'] as String? ?? 'Unknown',
            role: c['participantRole'] as String? ??
                c['subject'] as String? ?? '',
            avatarUrl: c['avatar'] as String? ?? '',
            avatarIcon: null,
            avatarColor: null,
            preview: c['lastMessage'] as String? ?? '',
            time: c['lastMessageTime'] as String? ??
                c['updatedAt'] as String? ?? '',
            hasCheckmark: c['read'] as bool? ?? false,
            isUnread: !(c['read'] as bool? ?? true),
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
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
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildSectionLabel(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.error)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _threads.isEmpty
                          ? Center(
                              child: Text('No conversations yet',
                                  style: TextStyle(
                                      color: Colors.grey.shade500)),
                            )
                          : _buildThreadList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
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
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search staff or subjects...',
            hintStyle:
                TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(Icons.search,
                color: Colors.grey.shade500, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'RECENT',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildThreadList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _threads.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) {
        return _ThreadTile(
          thread: _threads[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParentMessageViewScreen(
                  conversationId: _threads[index].id,
                  teacherName: _threads[index].name,
                  subject: _threads[index].role,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MessageThread {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final IconData? avatarIcon;
  final Color? avatarColor;
  final String preview;
  final String time;
  final bool hasCheckmark;
  final bool isUnread;

  _MessageThread({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    this.avatarIcon,
    this.avatarColor,
    required this.preview,
    required this.time,
    required this.hasCheckmark,
    required this.isUnread,
  });
}

class _ThreadTile extends StatelessWidget {
  final _MessageThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          thread.name,
                          style: TextStyle(
                            fontWeight: thread.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        thread.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: thread.isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: thread.isUnread
                              ? AppColors.primary
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.role,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.preview,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (thread.hasCheckmark)
                        Icon(
                          Icons.done_all,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      if (thread.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (thread.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(thread.avatarUrl),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor:
          (thread.avatarColor ?? AppColors.primary).withValues(alpha: 0.15),
      child: Icon(
        thread.avatarIcon ?? Icons.person,
        color: thread.avatarColor ?? AppColors.primary,
        size: 22,
      ),
    );
  }
}
