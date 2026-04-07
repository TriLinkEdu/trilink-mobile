import 'package:flutter/material.dart';

import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/theme_personalization.dart';

enum RoleThemeFlavor { student, teacher, parent }

class RolePageBackground extends StatelessWidget {
  final Widget child;
  final RoleThemeFlavor flavor;

  const RolePageBackground({
    super.key,
    required this.child,
    this.flavor = RoleThemeFlavor.student,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mood = ThemeNotifier.instance.effectiveMoodTheme;
    final texture = ThemeNotifier.instance.effectiveTextureStyle;
    final colors = _gradientColorsFor(mood, isDark, flavor);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.64, 1.0],
            ),
          ),
        ),
        if (texture == ThemeTextureStyle.paperGrain)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.white.withAlpha(5), Colors.black.withAlpha(8)]
                      : [Colors.white.withAlpha(26), Colors.black.withAlpha(5)],
                ),
              ),
            ),
          ),
        if (texture == ThemeTextureStyle.softMesh)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.85),
                  radius: 1.2,
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(isDark ? 34 : 24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        if (flavor != RoleThemeFlavor.student)
          IgnorePointer(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surface.withAlpha(isDark ? 74 : 96),
            ),
          ),
        child,
      ],
    );
  }

  List<Color> _gradientColorsFor(
    StudentMoodTheme mood,
    bool isDark,
    RoleThemeFlavor flavor,
  ) {
    final base = switch (mood) {
      StudentMoodTheme.focusBlue =>
        isDark
            ? const [Color(0xFF0A1526), Color(0xFF10263D), Color(0xFF122A44)]
            : const [Color(0xFFF2FAFF), Color(0xFFE8F5FF), Color(0xFFF7FCFF)],
      StudentMoodTheme.energyOrange =>
        isDark
            ? const [Color(0xFF24140B), Color(0xFF3A2313), Color(0xFF442A17)]
            : const [Color(0xFFFFF5EB), Color(0xFFFFEAD7), Color(0xFFFFF9F2)],
      StudentMoodTheme.calmMint =>
        isDark
            ? const [Color(0xFF0A1A19), Color(0xFF12302D), Color(0xFF163934)]
            : const [Color(0xFFEFFFF8), Color(0xFFDDF9F2), Color(0xFFF5FFFC)],
      StudentMoodTheme.sunsetCoral =>
        isDark
            ? const [Color(0xFF271418), Color(0xFF3A1F27), Color(0xFF462431)]
            : const [Color(0xFFFFF1F0), Color(0xFFFFE4DE), Color(0xFFFFF8F5)],
      StudentMoodTheme.midnightPurple =>
        isDark
            ? const [Color(0xFF141026), Color(0xFF211A3A), Color(0xFF271F44)]
            : const [Color(0xFFF5F2FF), Color(0xFFEAE4FF), Color(0xFFFBF9FF)],
    };

    if (flavor == RoleThemeFlavor.student) return base;

    final overlay = flavor == RoleThemeFlavor.teacher
        ? (isDark ? const Color(0xFF0B1220) : const Color(0xFFEFF4FF))
        : (isDark ? const Color(0xFF121922) : const Color(0xFFFFF7F1));

    final alpha = flavor == RoleThemeFlavor.teacher
        ? (isDark ? 132 : 164)
        : (isDark ? 120 : 154);

    return base
        .map((color) => Color.alphaBlend(overlay.withAlpha(alpha), color))
        .toList();
  }
}
