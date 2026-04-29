import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/di/injection_container.dart';
import 'package:trilink_mobile/core/services/sound_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import 'package:trilink_mobile/core/widgets/celebration_overlay.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../dashboard/widgets/student_shell_scope.dart';
import '../../shared/models/student_progress_model.dart';
import '../../shared/repositories/student_progress_repository.dart';
import '../../shared/widgets/student_page_background.dart';
import '../repositories/student_profile_repository.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late final StudentProfileRepository _repo;
  late final StudentProgressRepository _progressRepo;
  final StorageService _storage = sl<StorageService>();

  bool _pushNotifications = true;
  String _language = 'English';

  int _avatarTapCount = 0;
  late final AnimationController _avatarSpinController;
  StudentProgressModel? _progress;

  @override
  void initState() {
    super.initState();
    _repo = sl<StudentProfileRepository>();
    _progressRepo = sl<StudentProgressRepository>();
    _avatarSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadPreferences();
    _loadProgress();
  }

  @override
  void dispose() {
    _avatarSpinController.dispose();
    super.dispose();
  }

  void _onAvatarTap() {
    _avatarTapCount++;
    if (_avatarTapCount == 5) {
      HapticFeedback.selectionClick();
    } else if (_avatarTapCount == 6) {
      HapticFeedback.lightImpact();
    } else if (_avatarTapCount >= 7) {
      _avatarTapCount = 0;
      _avatarSpinController.forward(from: 0);
      sl<SoundService>().play(AppFeedback.achievement);
      CelebrationOverlay.maybeOf(context)?.celebrate(
        type: CelebrationType.achievement,
        message: 'Easter Egg Found!',
        subtext: 'You\'re a curious one!',
      );
    }
  }

  void _loadPreferences() {
    setState(() {
      _pushNotifications = _storage.getBool(
        'pushNotifications',
        defaultValue: true,
      );
      _language = _storage.getString('language') ?? 'English';
    });
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await _progressRepo.fetchProgress();
      if (!mounted) return;
      setState(() => _progress = progress);
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inShell = StudentShellScope.maybeOf(context) != null;
    final user = context.select((AuthCubit cubit) => cubit.currentUser);
    final displayName = user?.name ?? 'Student';
    final gradeSection = [
      if (user?.grade != null) user!.grade!,
      if (user?.section != null) user!.section!,
    ].join(' • ');
    final studentId = user?.id ?? '';

    return Scaffold(
      body: StudentPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (!inShell)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(RouteNames.studentNotifications),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      AppSpacing.gapMd,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withAlpha(225),
                          borderRadius: AppRadius.borderXl,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withAlpha(
                              90,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _onAvatarTap,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.bottomRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: AppRadius.borderXl,
                                    child: SizedBox(
                                      width: 112,
                                      height: 112,
                                      child: AnimatedBuilder(
                                        animation: _avatarSpinController,
                                        builder: (context, child) =>
                                            Transform.rotate(
                                              alignment: Alignment.center,
                                              angle:
                                                  _avatarSpinController.value *
                                                  2 *
                                                  pi,
                                              child: child,
                                            ),
                                        child: _StudentAvatarImage(user: user),
                                      ),
                                    ),
                                  ),
                                  Pressable(
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(RouteNames.studentProfileEdit),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.subtle(
                                          theme.shadowColor,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.gapLg,
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              gradeSection.isNotEmpty
                                  ? '$gradeSection • ID: $studentId'
                                  : 'ID: $studentId',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.gapSm,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: AppRadius.borderLg,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  AppSpacing.hGapXs,
                                  Text(
                                    _progress != null
                                        ? 'Level ${_progress!.level} ${_progress!.levelTitle}'
                                        : 'Level --',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapXl,

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 560;
                          final cardWidth = isCompact
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 14) / 2;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _ProfileGroupCard(
                                  title: 'Account',
                                  compact: isCompact,
                                  children: [
                                    _SettingsRow(
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(
                                            RouteNames.studentProfileEdit,
                                          ),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.lock_outline,
                                      label: 'Password',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: _showChangePasswordDialog,
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.language_rounded,
                                      label: 'Language',
                                      trailing: Text(
                                        _language,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: _showLanguagePicker,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _ProfileGroupCard(
                                  title: 'Preferences',
                                  compact: isCompact,
                                  children: [
                                    _SettingsRow(
                                      icon: Icons.notifications_outlined,
                                      label: 'Push Notifications',
                                      compact: isCompact,
                                      trailing: Switch(
                                        value: _pushNotifications,
                                        onChanged: (v) {
                                          setState(
                                            () => _pushNotifications = v,
                                          );
                                          _storage.setBool(
                                            'pushNotifications',
                                            v,
                                          );
                                        },
                                      ),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.dark_mode_outlined,
                                      label: 'Dark Mode',
                                      compact: isCompact,
                                      trailing: Switch(
                                        value: ThemeNotifier.instance.isDark,
                                        onChanged: (v) {
                                          if (v) {
                                            ThemeNotifier.instance.setDark();
                                          } else {
                                            ThemeNotifier.instance.setLight();
                                          }
                                        },
                                      ),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.text_fields_rounded,
                                      label: 'Text Size',
                                      compact: isCompact,
                                      trailing: Text(
                                        ThemeNotifier.instance.textScaleLabel,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      showChevron: true,
                                      onTap: _showTextSizePicker,
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.font_download_outlined,
                                      label: 'Font Family',
                                      compact: isCompact,
                                      trailing: Text(
                                        ThemeNotifier.instance.fontFamily,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      showChevron: true,
                                      onTap: _showFontFamilyPicker,
                                    ),
                                    _divider(),
                                    ListenableBuilder(
                                      listenable: sl<SoundService>(),
                                      builder: (context, _) {
                                        final soundService = sl<SoundService>();
                                        return _SettingsRow(
                                          icon: Icons.graphic_eq_rounded,
                                          label: 'Sound Effects',
                                          compact: isCompact,
                                          trailing: Switch(
                                            value: soundService.enabled,
                                            onChanged: (v) =>
                                                soundService.setEnabled(v),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _ProfileGroupCard(
                                  title: 'Support',
                                  compact: isCompact,
                                  children: [
                                    _SettingsRow(
                                      icon: Icons.help_outline_rounded,
                                      label: 'Help Center',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: _showHelpCenter,
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.bug_report_outlined,
                                      label: 'Report a Bug',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: _showBugReport,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _ProfileGroupCard(
                                  title: 'Quick Links',
                                  compact: isCompact,
                                  children: [
                                    _SettingsRow(
                                      icon: Icons.assignment_outlined,
                                      label: 'Assignments',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(
                                            RouteNames.studentAssignments,
                                          ),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.calendar_month_outlined,
                                      label: 'Calendar',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pushNamed(RouteNames.studentCalendar),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.folder_outlined,
                                      label: 'Courses & Resources',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pushNamed(RouteNames.studentCourses),
                                    ),
                                    _divider(),
                                    _SettingsRow(
                                      icon: Icons.more_horiz_rounded,
                                      label: 'More Links',
                                      compact: isCompact,
                                      showChevron: true,
                                      onTap: _showMoreLinks,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      AppSpacing.gapXxl,

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            await context.read<AuthCubit>().logout();
                            if (!context.mounted) return;
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamedAndRemoveUntil(
                              RouteNames.login,
                              (_) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMd,
                            ),
                          ),
                          child: Text(
                            'Log Out',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapMd,
                      Text(
                        'Version 2.4.0 (Build 302)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapXxl,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant,
      indent: 50,
    );
  }

  void _showChangePasswordDialog() {
    final oldPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: newPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: confirmPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != newPwController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              try {
                await _repo.changePassword(
                  oldPassword: oldPwController.text,
                  newPassword: newPwController.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
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
              ListTile(
                title: const Text('English'),
                trailing: _language == 'English'
                    ? Icon(Icons.check, color: sheetTheme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _language = 'English');
                  _storage.setString('language', 'English');
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                title: const Text('Amharic'),
                trailing: _language == 'Amharic'
                    ? Icon(Icons.check, color: sheetTheme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _language = 'Amharic');
                  _storage.setString('language', 'Amharic');
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextSizePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final tn = ThemeNotifier.instance;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapMd,
              Text('Choose Text Size', style: sheetTheme.textTheme.titleMedium),
              AppSpacing.gapSm,
              for (final entry in ThemeNotifier.scaleOptions.entries)
                ListTile(
                  title: Text(entry.key),
                  subtitle: Text(
                    'Aa Bb Cc',
                    style: TextStyle(
                      fontSize:
                          sheetTheme.textTheme.bodyMedium!.fontSize! *
                          entry.value,
                    ),
                  ),
                  trailing: tn.textScaleLabel == entry.key
                      ? Icon(
                          Icons.check_circle,
                          color: sheetTheme.colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    tn.setTextScale(entry.key);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              AppSpacing.gapMd,
            ],
          ),
        );
      },
    );
  }

  void _showFontFamilyPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final tn = ThemeNotifier.instance;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.75,
          expand: false,
          builder: (_, scrollController) => SafeArea(
            child: Column(
              children: [
                AppSpacing.gapMd,
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetTheme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppSpacing.gapMd,
                Text(
                  'Choose Font Family',
                  style: sheetTheme.textTheme.titleMedium,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: ThemeNotifier.availableFonts.length,
                    itemBuilder: (_, i) {
                      final font = ThemeNotifier.availableFonts[i];
                      final isSelected = tn.fontFamily == font;
                      return ListTile(
                        title: Text(
                          font,
                          style: TextStyle(
                            fontFamily: font,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          'The quick brown fox jumps over the lazy dog',
                          style: sheetTheme.textTheme.bodySmall?.copyWith(
                            fontFamily: font,
                            color: sheetTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: sheetTheme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          tn.setFontFamily(font);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpCenter() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                question: 'How do I check my grades?',
                answer:
                    'Navigate to the Grades tab from the bottom navigation bar to view all your subject grades.',
              ),
              AppSpacing.gapMd,
              _FaqItem(
                question: 'How do I contact my teacher?',
                answer:
                    'Use the Chat section to send a direct message to any of your teachers.',
              ),
              AppSpacing.gapMd,
              _FaqItem(
                question: 'How do I submit assignments?',
                answer:
                    'Open Assignments from the dashboard, select the assignment, and tap "Submit" to upload your work.',
              ),
              AppSpacing.gapMd,
              _FaqItem(
                question: 'How do I reset my password?',
                answer:
                    'Go to Profile > Password, or log out and tap "Forgot password?" on the login screen.',
              ),
            ],
          ),
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

  void _showBugReport() {
    final bugController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report a Bug'),
        content: TextField(
          controller: bugController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue you encountered...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (bugController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bug report submitted. Thank you for your feedback!',
                  ),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showMoreLinks() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(
                  context,
                ).pushNamed(RouteNames.studentNotifications);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Chat'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                final shell = StudentShellScope.maybeOf(context);
                if (shell != null) {
                  shell.switchTab(2);
                } else {
                  Navigator.of(context).pushNamed(RouteNames.studentChat);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('App Settings'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(RouteNames.studentSettings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(RouteNames.studentAttendance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(RouteNames.studentFeedback);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: const Text('Sync Status'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(RouteNames.studentSyncStatus);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Exam Attempt'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(RouteNames.studentExamAttempt);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentAvatarImage extends StatelessWidget {
  final dynamic user;

  const _StudentAvatarImage({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profilePath = (user?.profileImagePath ?? '').toString();
    final hasImage = profilePath.isNotEmpty;

    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      child: hasImage
          ? Image.network(
              profilePath.startsWith('http') ? profilePath : '${ApiConstants.fileBaseUrl}$profilePath',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: 62,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: 62,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapXs,
        Text(
          answer,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool compact;

  const _ProfileGroupCard({
    required this.title,
    required this.children,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 4 : 6,
                16,
                compact ? 6 : 8,
              ),
              child: Text(
                title,
                style:
                    (compact
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool compact;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: compact ? 20 : 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: compact ? 10 : 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: compact ? 8 : 10),
              Align(alignment: Alignment.centerRight, child: trailing!),
            ],
            if (showChevron)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
