import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/di/injection_container.dart';
import 'package:trilink_mobile/core/services/sound_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import 'package:trilink_mobile/core/widgets/celebration_overlay.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../shared/models/student_progress_model.dart';
import '../../shared/repositories/student_progress_repository.dart';
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
    final progress = await _progressRepo.fetchProgress();
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthCubit>().currentUser;
    final displayName = user?.name ?? 'Student';
    final displayEmail = user?.email ?? 'No email';
    final gradeSection = [
      if (user?.grade != null) user!.grade!,
      if (user?.section != null) user!.section!,
    ].join(' • ');
    final studentId = user?.id ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentProfileEdit),
                    child: Text(
                      'Edit Profile',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
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
                    AppSpacing.gapMd,
                    GestureDetector(
                      onTap: _onAvatarTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: AnimatedBuilder(
                                animation: _avatarSpinController,
                                builder: (context, child) => Transform.rotate(
                                  alignment: Alignment.center,
                                  angle: _avatarSpinController.value * 2 * pi,
                                  child: child,
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor:
                                      theme.colorScheme.outlineVariant,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Pressable(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Photo picker will use device camera/gallery when integrated',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      gradeSection.isNotEmpty
                          ? '$gradeSection • ID: $studentId'
                          : 'ID: $studentId',
                      style: theme.textTheme.labelLarge?.copyWith(
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapXxxl,

                    _SectionHeader(title: 'ACCOUNT'),
                    AppSpacing.gapSm,
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          trailing: Text(
                            displayEmail,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.hGapXs,
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: _showLanguagePicker,
                        ),
                      ],
                    ),
                    AppSpacing.gapXxl,

                    _SectionHeader(title: 'PREFERENCES'),
                    AppSpacing.gapSm,
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          label: 'Push Notifications',
                          trailing: Switch(
                            value: _pushNotifications,
                            onChanged: (v) {
                              setState(() => _pushNotifications = v);
                              _storage.setBool('pushNotifications', v);
                            },
                          ),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
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
                        ListenableBuilder(
                          listenable: sl<SoundService>(),
                          builder: (context, _) {
                            final soundService = sl<SoundService>();
                            return _SettingsRow(
                              icon: Icons.graphic_eq_rounded,
                              label: 'Sound Effects',
                              trailing: Switch(
                                value: soundService.enabled,
                                onChanged: (v) => soundService.setEnabled(v),
                              ),
                            );
                          },
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.text_fields_rounded,
                          label: 'Text Size',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ThemeNotifier.instance.textScaleLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.hGapXs,
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: _showTextSizePicker,
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.font_download_outlined,
                          label: 'Font Family',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ThemeNotifier.instance.fontFamily,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.hGapXs,
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: _showFontFamilyPicker,
                        ),
                      ],
                    ),
                    AppSpacing.gapXxl,

                    _SectionHeader(title: 'SUPPORT'),
                    AppSpacing.gapSm,
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
                    AppSpacing.gapXxl,

                    _SectionHeader(title: 'NAVIGATION'),
                    AppSpacing.gapSm,
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
                        _divider(),
                        _SettingsRow(
                          icon: Icons.assignment_outlined,
                          label: 'Assignments',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentAssignments),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.folder_outlined,
                          label: 'Courses & Resources',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentCourseResources),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.fact_check_outlined,
                          label: 'Exam Attempt',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentExamAttempt),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.sync_outlined,
                          label: 'Sync Status',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentSyncStatus),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.fact_check_outlined,
                          label: 'Attendance',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentAttendance),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: Icons.rate_review_outlined,
                          label: 'Feedback',
                          showChevron: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.studentFeedback),
                        ),
                      ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
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
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            AppSpacing.hGapLg,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!],
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
