import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool _systemAnnouncements = true;
  bool _enhancedPrivacy = false;
  bool _darkMode = ThemeNotifier.instance.isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildSection('PERSONAL INFORMATION', [
              _SettingsTile(title: 'Edit Profile', onTap: () {}),
              _SettingsTile(title: 'Change Password', onTap: () {}),
            ]),
            const SizedBox(height: 24),
            _buildLinkedChildren(),
            const SizedBox(height: 24),
            _buildNotificationPreferences(),
            const SizedBox(height: 24),
            _buildAppSettings(),
            const SizedBox(height: 32),
            _buildLogout(),
            const SizedBox(height: 12),
            _buildVersionInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/120?img=32',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sarah Jenkins',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sarah.jenkins@example.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildLinkedChildren() {
    return _buildSection('LINKED CHILDREN', [
      _ChildTile(
        name: 'Alex Jenkins',
        schoolId: 'School ID: •••• 4821',
        avatarUrl: 'https://i.pravatar.cc/80?img=60',
        onManage: () {},
      ),
      _ChildTile(
        name: 'Mia Jenkins',
        schoolId: 'School ID: •••• 9932',
        avatarUrl: 'https://i.pravatar.cc/80?img=47',
        onManage: () {},
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Child by School ID',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildNotificationPreferences() {
    return _buildSection('NOTIFICATION PREFERENCES', [
      _SettingsTile(
        title: "Alex's Alerts",
        trailing: Text(
          'Custom',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        onTap: () {},
      ),
      _SettingsTile(
        title: "Mia's Alerts",
        trailing: Text(
          'All On',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        onTap: () {},
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Announcements',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updates about TriLink ecosystem',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _systemAnnouncements,
              onChanged: (val) =>
                  setState(() => _systemAnnouncements = val),
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAppSettings() {
    return _buildSection('APP SETTINGS', [
      _SettingsTile(
        title: 'Language',
        trailing: Text(
          'English (US)',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        onTap: () {},
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Dark Mode',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
                ThemeNotifier.instance.toggle();
              },
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enhanced Privacy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Automatically deletes detailed activity logs older than 30 days.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _enhancedPrivacy,
              onChanged: (val) =>
                  setState(() => _enhancedPrivacy = val),
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildLogout() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'TriLink App Version 1.0.2 (Build 450)',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final String name;
  final String schoolId;
  final String avatarUrl;
  final VoidCallback onManage;

  const _ChildTile({
    required this.name,
    required this.schoolId,
    required this.avatarUrl,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  schoolId,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onManage,
            child: Text(
              'Manage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
