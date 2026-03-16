import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'parent_message_view_screen.dart';

class ParentChatScreen extends StatelessWidget {
  const ParentChatScreen({super.key});

  static final List<_MessageThread> _threads = [
    _MessageThread(
      name: 'Mrs. Sarah Jenkins',
      role: 'Mathematics - Grade 10',
      avatarUrl: 'https://i.pravatar.cc/100?img=32',
      preview: 'Please ensure the permission slip for th...',
      time: '10:30 AM',
      hasCheckmark: true,
      isUnread: false,
    ),
    _MessageThread(
      name: 'Mr. David Ross',
      role: 'History - Grade 11',
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      preview: 'The mid-term results have been poste...',
      time: 'Yesterday',
      hasCheckmark: true,
      isUnread: false,
    ),
    _MessageThread(
      name: 'Administration Office',
      role: 'General Announcement',
      avatarUrl: '',
      avatarIcon: Icons.business,
      avatarColor: AppColors.primary,
      preview: 'Reminder: School closes early this Frid...',
      time: 'Tue',
      hasCheckmark: true,
      isUnread: false,
    ),
    _MessageThread(
      name: 'Mrs. Emily Chen',
      role: 'Physics - Grade 11',
      avatarUrl: 'https://i.pravatar.cc/100?img=20',
      preview: 'Lab coat fees are due by next week.',
      time: 'Mon',
      hasCheckmark: true,
      isUnread: false,
    ),
    _MessageThread(
      name: 'Coach Mike',
      role: 'Athletics Department',
      avatarUrl: 'https://i.pravatar.cc/100?img=51',
      preview: 'Practice schedule change for the varsit...',
      time: 'Sat',
      hasCheckmark: false,
      isUnread: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildSectionLabel(),
            Expanded(child: _buildThreadList(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
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
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
