import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/theme_personalization.dart';
import '../widgets/role_page_background.dart';

class ThemeCustomizationScreen extends StatelessWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme and Appearance')),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: ListenableBuilder(
          listenable: ThemeNotifier.instance,
          builder: (context, _) {
            final tn = ThemeNotifier.instance;
            final dividerColor = theme.colorScheme.outlineVariant.withAlpha(
              isDark ? 120 : 160,
            );

            return ListView(
              padding: AppSpacing.paddingMd,
              children: [
                _SectionCard(
                  title: 'Display',
                  isDark: isDark,
                  children: [
                    _AdaptiveToggleTile(
                      title: 'Dark Mode',
                      subtitle: 'Use a darker theme for low-light viewing.',
                      value: tn.isDark,
                      onChanged: (value) {
                        if (value) {
                          tn.setDark();
                        } else {
                          tn.setLight();
                        }
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    _AdaptiveToggleTile(
                      title: 'Auto Apply Themes',
                      subtitle: 'Automatically switch theme by time of day.',
                      value: tn.autoApplyThemes,
                      onChanged: tn.setAutoApplyThemes,
                    ),
                    Divider(height: 1, color: dividerColor),
                    _AdaptiveToggleTile(
                      title: 'Theme Preview',
                      subtitle: 'See live changes before applying.',
                      value: tn.previewEnabled,
                      onChanged: tn.setPreviewEnabled,
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      title: const Text('Schedule Type'),
                      subtitle: const Text('Time of day'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          tn.setScheduleMode(ThemeScheduleMode.timeOfDay),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                _SectionCard(
                  title: 'Mood Theme',
                  isDark: isDark,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: StudentMoodTheme.values.map((mood) {
                          final selected = tn.effectiveMoodTheme == mood;
                          final label = moodThemeLabels[mood] ?? mood.name;
                          return _MoodThemeChip(
                            label: label,
                            selected: selected,
                            color: _moodChipColor(mood),
                            onTap: () {
                              if (tn.previewEnabled) {
                                tn.setPreviewMoodTheme(mood);
                              } else {
                                tn.setSelectedMoodTheme(mood);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                _SectionCard(
                  title: 'Background Texture',
                  isDark: isDark,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ThemeTextureStyle.values.map((texture) {
                          final selected = tn.effectiveTextureStyle == texture;
                          final label =
                              textureStyleLabels[texture] ?? texture.name;
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
                  ],
                ),
                if (tn.previewEnabled) ...[
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: tn.cancelPreview,
                          child: const Text('Cancel Preview'),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: FilledButton(
                          onPressed: tn.applyPreview,
                          child: const Text('Apply Preview'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
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
                fontWeight: FontWeight.w700,
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

class _MoodThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MoodThemeChip({
    required this.label,
    required this.selected,
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
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? onSelected : onUnselected,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
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
