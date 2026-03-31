import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../auth/services/auth_service.dart';

/// Personalization options (themes, notifications, privacy).
class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricLock = false;
  String _language = 'English';

  Future<void> _showLanguagePicker() async {
    final language = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        const options = ['English', 'Amharic', 'Afaan Oromo'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Choose Language',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == _language
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (language == null || !mounted) {
      return;
    }

    setState(() => _language = language);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await AuthService().logout();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Display',
            children: [
              SwitchListTile.adaptive(
                value: ThemeNotifier.instance.isDark,
                onChanged: (value) {
                  if (value) {
                    ThemeNotifier.instance.setDark();
                  } else {
                    ThemeNotifier.instance.setLight();
                  }
                },
                activeTrackColor: AppColors.primary,
                title: const Text('Dark Mode'),
                subtitle: const Text('Use a darker theme for low-light viewing.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Notifications',
            children: [
              SwitchListTile.adaptive(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                activeTrackColor: AppColors.primary,
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive updates about classes and announcements.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Privacy',
            children: [
              SwitchListTile.adaptive(
                value: _biometricLock,
                onChanged: (value) {
                  setState(() => _biometricLock = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Biometric lock enabled for next sign-in.'
                            : 'Biometric lock disabled.',
                      ),
                    ),
                  );
                },
                activeTrackColor: AppColors.primary,
                title: const Text('Biometric Lock'),
                subtitle: const Text('Require biometric verification on app open.'),
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_language),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguagePicker,
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log Out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
