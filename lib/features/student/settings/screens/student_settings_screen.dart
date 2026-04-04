import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../../auth/cubit/auth_cubit.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final StorageService _storage = sl<StorageService>();

  bool _notificationsEnabled = true;
  bool _biometricLock = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _notificationsEnabled = _storage.getBool(
        'pushNotifications',
        defaultValue: true,
      );
      _biometricLock = _storage.getBool('biometricLock');
      _language = _storage.getString('language') ?? 'English';
    });
  }

  Future<void> _showLanguagePicker() async {
    final language = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        const options = ['English', 'Amharic', 'Afaan Oromo'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapMd,
              Text(
                'Choose Language',
                style: sheetTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapMd,
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == _language
                      ? Icon(Icons.check, color: sheetTheme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
              ),
              AppSpacing.gapSm,
            ],
          ),
        );
      },
    );

    if (language == null || !mounted) return;

    setState(() => _language = language);
    await _storage.setString('language', language);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
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

    if (shouldLogout != true || !mounted) return;

    await context.read<AuthCubit>().logout();
    if (!mounted) return;

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StudentPageBackground(
        child: ListView(
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
                    setState(() {});
                  },
                  title: const Text('Dark Mode'),
                  subtitle: const Text(
                    'Use a darker theme for low-light viewing.',
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            _SectionCard(
              title: 'Notifications',
              children: [
                SwitchListTile.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _storage.setBool('pushNotifications', value);
                  },
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'Receive updates about classes and announcements.',
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            _SectionCard(
              title: 'Privacy',
              children: [
                SwitchListTile.adaptive(
                  value: _biometricLock,
                  onChanged: (value) {
                    setState(() => _biometricLock = value);
                    _storage.setBool('biometricLock', value);
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
                  title: const Text('Biometric Lock'),
                  subtitle: const Text(
                    'Require biometric verification on app open.',
                  ),
                ),
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguagePicker,
                ),
              ],
            ),
            AppSpacing.gapXl,
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text(
                'Log Out',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMd,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
