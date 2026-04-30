import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/role_page_background.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = ThemeNotifier.instance.isDark;

  String _textSize = ThemeNotifier.instance.textScaleLabel;
  String _fontFamily = ThemeNotifier.instance.fontFamily;

  @override
  void initState() {
    super.initState();
    final notifier = ThemeNotifier.instance;
    _darkMode = notifier.isDark;
    _textSize = notifier.textScaleLabel;
    _fontFamily = notifier.fontFamily;
  }

  Future<void> _showTextSizePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final options = ThemeNotifier.scaleOptions.keys.toList();
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapMd,
              Text(
                'Text Size',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              AppSpacing.gapMd,
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == _textSize
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
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
    if (selected == null || !mounted) return;
    setState(() => _textSize = selected);
    ThemeNotifier.instance.setTextScale(selected);
  }

  Future<void> _showFontFamilyPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final options = ThemeNotifier.availableFonts;
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapMd,
              Text(
                'Font Family',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              AppSpacing.gapMd,
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == _fontFamily
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
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
    if (selected == null || !mounted) return;
    setState(() => _fontFamily = selected);
    ThemeNotifier.instance.setFontFamily(selected);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        theme.colorScheme.outlineVariant.withAlpha(isDark ? 120 : 170);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Teacher Preferences',
              isDark: isDark,
              children: [
                _AdaptiveToggleTile(
                  icon: Icons.notifications_none,
                  title: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                Divider(height: 1, color: dividerColor),
                _AdaptiveToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    if (value) {
                      ThemeNotifier.instance.setDark();
                    } else {
                      ThemeNotifier.instance.setLight();
                    }
                  },
                ),
                Divider(height: 1, color: dividerColor),
                _AdaptiveActionTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme & Appearance',
                  valueText: 'Customize',
                  onTap: () => Navigator.pushNamed(
                      context, RouteNames.themeCustomization),
                ),
                Divider(height: 1, color: dividerColor),
                _AdaptiveActionTile(
                  icon: Icons.text_fields,
                  title: 'Text Size',
                  valueText: _textSize,
                  onTap: _showTextSizePicker,
                ),
                Divider(height: 1, color: dividerColor),
                _AdaptiveActionTile(
                  icon: Icons.font_download_outlined,
                  title: 'Font Family',
                  valueText: _fontFamily,
                  onTap: _showFontFamilyPicker,
                ),
              ],
            ),
            AppSpacing.gapLg,
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

// ─── Shared widgets (same as parent settings) ────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark
          ? theme.colorScheme.surface.withAlpha(220)
          : theme.colorScheme.surface.withAlpha(246),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

class _AdaptiveToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AdaptiveToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AdaptiveActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueText;
  final VoidCallback onTap;

  const _AdaptiveActionTile({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading:
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
