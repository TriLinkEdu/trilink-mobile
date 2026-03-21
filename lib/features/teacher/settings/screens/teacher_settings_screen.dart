import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _predictiveInsights = true;
  bool _darkMode = ThemeNotifier.instance.isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back',
            style: TextStyle(color: AppColors.primary, fontSize: 15),
          ),
        ),
        leadingWidth: 70,
        title: const Text(
          'Profile & Settings',
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
              'Edit',
              style: TextStyle(color: AppColors.primary, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileHeader(),
            const SizedBox(height: 28),
            _buildAccountSection(),
            const SizedBox(height: 20),
            _buildSignatureSection(),
            const SizedBox(height: 20),
            _buildPreferencesSection(),
            const SizedBox(height: 20),
            _buildSupportSection(),
            const SizedBox(height: 16),
            _buildLogout(),
            const SizedBox(height: 12),
            _buildVersionInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=32'),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Sarah Jenkins',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Senior Mathematics • Homeroom 10B',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'ID: 894021',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _Section(
      label: 'ACCOUNT',
      children: [
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Personal Information',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.draw_outlined,
          title: 'Digital Signature',
          trailing: Text(
            'Configured',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Authorized Signature',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This signature is securely stored and used to authorize student report cards.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _Section(
      label: 'PREFERENCES',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Predictive Insights',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enable AI analysis for early warning alerts on student performance trends.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _predictiveInsights,
                onChanged: (val) =>
                    setState(() => _predictiveInsights = val),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _darkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
        _SettingsTile(
          icon: Icons.accessibility_new,
          title: 'Accessibility',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _Section(
      label: 'SUPPORT',
      children: [
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          iconColor: AppColors.error,
          trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLogout() {
    return GestureDetector(
      onTap: () {},
      child: const Text(
        'Log Out',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      'TriLink v2.4.1 (Build 892)',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.iconColor,
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
            Icon(icon, size: 22, color: iconColor ?? Colors.grey.shade700),
            const SizedBox(width: 14),
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
