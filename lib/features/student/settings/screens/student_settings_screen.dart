import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/theme/theme_personalization.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../cubit/student_settings_cubit.dart';
import '../cubit/student_settings_state.dart';
import '../repositories/student_settings_repository.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final StorageService _storage = sl<StorageService>();
  late final StudentSettingsCubit _settingsCubit = StudentSettingsCubit(
    sl<StudentSettingsRepository>(),
    _storage,
  );

  bool _notificationsEnabled = true;
  bool _biometricLock = false;
  String _language = 'English';

  bool _isRareThemeUnlocked(StudentMoodTheme mood) {
    if (mood != StudentMoodTheme.midnightPurple) return true;
    final streak = _storage.getInt('mockCurrentStreak', defaultValue: 12);
    return streak >= 14;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _settingsCubit.loadSettings();
  }

  @override
  void dispose() {
    _settingsCubit.close();
    super.dispose();
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
    await _settingsCubit.setLanguage(language);
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
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = theme.colorScheme.outlineVariant.withAlpha(
      isDark ? 120 : 160,
    );

    return BlocProvider.value(
      value: _settingsCubit,
      child: BlocListener<StudentSettingsCubit, StudentSettingsState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state.status == StudentSettingsStatus.loaded) {
            setState(() {
              _language = state.language;
              _notificationsEnabled = state.notificationsEnabled;
              _biometricLock = state.biometricLock;
            });
          }

          final msg = state.errorMessage;
          if (msg == null || msg.isEmpty) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: StudentPageBackground(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Display',
                  isDark: isDark,
                  children: [
                    ListenableBuilder(
                      listenable: ThemeNotifier.instance,
                      builder: (context, _) {
                        final tn = ThemeNotifier.instance;
                        return Column(
                          children: [
                            _AdaptiveToggleTile(
                              title: 'Dark Mode',
                              subtitle:
                                  'Use a darker theme for low-light viewing.',
                              value: tn.isDark,
                              onChanged: (value) {
                                if (value) {
                                  tn.setDark();
                                } else {
                                  tn.setLight();
                                }
                                setState(() {});
                              },
                            ),
                            Divider(height: 1, color: dividerColor),
                            _AdaptiveToggleTile(
                              title: 'Auto Apply Themes',
                              subtitle:
                                  'Automatically switch theme by time of day.',
                              value: tn.autoApplyThemes,
                              onChanged: (value) {
                                tn.setAutoApplyThemes(value);
                                setState(() {});
                              },
                            ),
                            Divider(height: 1, color: dividerColor),
                            _AdaptiveToggleTile(
                              title: 'Theme Preview',
                              subtitle: 'See live changes before applying.',
                              value: tn.previewEnabled,
                              onChanged: (value) => tn.setPreviewEnabled(value),
                            ),
                            Divider(height: 1, color: dividerColor),
                            ListTile(
                              title: const Text('Schedule Type'),
                              subtitle: Text(
                                tn.scheduleMode == ThemeScheduleMode.timeOfDay
                                    ? 'Time of day'
                                    : 'Time of day',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                tn.setScheduleMode(ThemeScheduleMode.timeOfDay);
                              },
                            ),
                            Divider(height: 1, color: dividerColor),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mood Themes',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: StudentMoodTheme.values.map((mood) {
                                  final unlocked = _isRareThemeUnlocked(mood);
                                  final selected =
                                      tn.effectiveMoodTheme == mood;
                                  final label =
                                      moodThemeLabels[mood] ?? mood.name;
                                  return _MoodThemeChip(
                                    label: label,
                                    selected: selected,
                                    locked: !unlocked,
                                    color: _moodChipColor(mood),
                                    onTap: unlocked
                                        ? () {
                                            if (tn.previewEnabled) {
                                              tn.setPreviewMoodTheme(mood);
                                            } else {
                                              tn.setSelectedMoodTheme(mood);
                                            }
                                          }
                                        : null,
                                  );
                                }).toList(),
                              ),
                            ),
                            if (!_isRareThemeUnlocked(
                              StudentMoodTheme.midnightPurple,
                            ))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  'Unlock Midnight Purple with a 14-day study streak.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            Divider(height: 1, color: dividerColor),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Background Texture',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ThemeTextureStyle.values.map((
                                  texture,
                                ) {
                                  final selected =
                                      tn.effectiveTextureStyle == texture;
                                  final label =
                                      textureStyleLabels[texture] ??
                                      texture.name;
                                  return _TextureChip(
                                    label: label,
                                    selected: selected,
                                    texture: texture,
                                    onTap: () {
                                      if (tn.previewEnabled) {
                                        tn.setPreviewTextureStyle(texture);
                                      } else {
                                        tn.setTextureStyle(texture);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            if (tn.previewEnabled)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: tn.cancelPreview,
                                        child: const Text('Cancel Preview'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: tn.applyPreview,
                                        child: const Text('Apply Preview'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                _SectionCard(
                  title: 'Notifications',
                  isDark: isDark,
                  children: [
                    _AdaptiveToggleTile(
                      title: 'Push Notifications',
                      subtitle:
                          'Receive updates about classes and announcements.',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _storage.setBool('pushNotifications', value);
                        _settingsCubit.setNotificationsEnabled(value);
                      },
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                _SectionCard(
                  title: 'Privacy',
                  isDark: isDark,
                  children: [
                    _AdaptiveToggleTile(
                      title: 'Biometric Lock',
                      subtitle: 'Require biometric verification on app open.',
                      value: _biometricLock,
                      onChanged: (value) {
                        setState(() => _biometricLock = value);
                        _storage.setBool('biometricLock', value);
                        _settingsCubit.setBiometricLock(value);
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
                    ),
                    Divider(height: 1, color: dividerColor),
                    _AdaptiveActionTile(
                      title: 'Language',
                      valueText: _language,
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
        ),
      ),
    );
  }
}

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

class _AdaptiveToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AdaptiveToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _AdaptiveActionTile extends StatelessWidget {
  final String title;
  final String valueText;
  final VoidCallback onTap;

  const _AdaptiveActionTile({
    required this.title,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _MoodThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final Color color;
  final VoidCallback? onTap;

  const _MoodThemeChip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = color;
    final unselectedBg = Color.alphaBlend(
      color.withAlpha(40),
      theme.colorScheme.surface,
    );
    final onSelected =
        ThemeData.estimateBrightnessForColor(selectedBg) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final onUnselected =
        ThemeData.estimateBrightnessForColor(unselectedBg) == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withAlpha(220) : color.withAlpha(90),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? onSelected : onUnselected,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: selected
                    ? onSelected
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextureChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeTextureStyle texture;
  final VoidCallback onTap;

  const _TextureChip({
    required this.label,
    required this.selected,
    required this.texture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHigh;
    final textColor = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    BoxDecoration decoration;
    switch (texture) {
      case ThemeTextureStyle.flat:
        decoration = BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withAlpha(210)
                : theme.colorScheme.outlineVariant,
          ),
        );
      case ThemeTextureStyle.paperGrain:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [base.withAlpha(220), base.withAlpha(170)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withAlpha(210)
                : theme.colorScheme.outlineVariant,
          ),
        );
      case ThemeTextureStyle.softMesh:
        decoration = BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.7, -0.8),
            radius: 1.2,
            colors: [
              (selected ? theme.colorScheme.primary : base).withAlpha(190),
              base,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withAlpha(210)
                : theme.colorScheme.outlineVariant,
          ),
        );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: decoration,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Color _moodChipColor(StudentMoodTheme mood) {
  switch (mood) {
    case StudentMoodTheme.focusBlue:
      return const Color(0xFF3B82F6);
    case StudentMoodTheme.energyOrange:
      return const Color(0xFFF97316);
    case StudentMoodTheme.calmMint:
      return const Color(0xFF34D399);
    case StudentMoodTheme.sunsetCoral:
      return const Color(0xFFFF6F61);
    case StudentMoodTheme.midnightPurple:
      return const Color(0xFF7C3AED);
  }
}
