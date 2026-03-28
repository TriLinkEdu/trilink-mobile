import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../auth/services/auth_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _pushNotifications = true;
  bool _darkMode = ThemeNotifier.instance.isDark;
  String _language = 'English';
  String _textSize = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Navigator.of(context).canPop()
                        ? IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                  const Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile editor will be available next.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Sara Mekonnen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade 11-B • ID: 2024098',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Level 12 Scholar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ACCOUNT section
                    _SectionHeader(title: 'ACCOUNT'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          trailing: Text(
                            'sara.m@trilink.edu',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.lock_outline,
                          label: 'Password',
                          showChevron: true,
                          onTap: _showChangePasswordDialog,
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.language_rounded,
                          label: 'Language',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _language,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          onTap: _showLanguagePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PREFERENCES section
                    _SectionHeader(title: 'PREFERENCES'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          label: 'Push Notifications',
                          trailing: Switch(
                            value: _pushNotifications,
                            onChanged: (v) =>
                                setState(() => _pushNotifications = v),
                            activeTrackColor: AppColors.primary,
                          ),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          trailing: Switch(
                            value: _darkMode,
                            onChanged: (v) {
                              setState(() => _darkMode = v);
                              ThemeNotifier.instance.toggle();
                            },
                            activeTrackColor: AppColors.primary,
                          ),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.text_fields_rounded,
                          label: 'Text Size',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _textSize,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          onTap: _showTextSizePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SUPPORT section
                    _SectionHeader(title: 'SUPPORT'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.help_outline_rounded,
                          label: 'Help Center',
                          showChevron: true,
                          onTap: _showHelpCenter,
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.bug_report_outlined,
                          label: 'Report a Bug',
                          showChevron: true,
                          onTap: _showBugReport,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // NAVIGATION section
                    _SectionHeader(title: 'NAVIGATION'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentNotifications),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.chat_outlined,
                          label: 'Chat',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentChat),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Calendar',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentCalendar),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.settings_outlined,
                          label: 'App Settings',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentSettings),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Log Out button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () async {
                          await AuthService().logout();
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Version 2.4.0 (Build 302)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.shade200,
      indent: 50,
    );
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password update flow is prepared and ready for API integration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() => _language = 'English');
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              title: const Text('Amharic'),
              onTap: () {
                setState(() => _language = 'Amharic');
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Small'),
              onTap: () {
                setState(() => _textSize = 'Small');
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              title: const Text('Default'),
              onTap: () {
                setState(() => _textSize = 'Default');
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              title: const Text('Large'),
              onTap: () {
                setState(() => _textSize = 'Large');
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpCenter() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text('Support docs and FAQ screen is ready for content integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text('Bug report form stub is ready for backend ticket submission integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!],
            if (showChevron)
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
