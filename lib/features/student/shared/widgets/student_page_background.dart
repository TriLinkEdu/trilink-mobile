import 'package:flutter/material.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/theme/theme_personalization.dart';

class StudentPageBackground extends StatelessWidget {
  final Widget child;

  const StudentPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mood = ThemeNotifier.instance.effectiveMoodTheme;
    final texture = ThemeNotifier.instance.effectiveTextureStyle;
    final colors = _gradientColorsForMood(mood, isDark);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              stops: isDark ? null : const [0.0, 0.62, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                      : [Colors.white.withAlpha(28), Colors.black.withAlpha(5)],
                ),
              ),
            ),
          ),
        if (texture == ThemeTextureStyle.softMesh)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.8),
                  radius: 1.2,
                  colors: isDark
                      ? [
                          Theme.of(context).colorScheme.primary.withAlpha(34),
                          Colors.transparent,
                        ]
                      : [
                          Theme.of(context).colorScheme.primary.withAlpha(24),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }

  List<Color> _gradientColorsForMood(StudentMoodTheme mood, bool isDark) {
    switch (mood) {
      case StudentMoodTheme.focusBlue:
        return isDark
            ? const [Color(0xFF0A1526), Color(0xFF10263D)]
            : const [Color(0xFFF2FAFF), Color(0xFFE8F5FF), Color(0xFFF7FCFF)];
      case StudentMoodTheme.energyOrange:
        return isDark
            ? const [Color(0xFF24140B), Color(0xFF3A2313)]
            : const [Color(0xFFFFF5EB), Color(0xFFFFEAD7), Color(0xFFFFF9F2)];
      case StudentMoodTheme.calmMint:
        return isDark
            ? const [Color(0xFF0A1A19), Color(0xFF12302D)]
            : const [Color(0xFFEFFFF8), Color(0xFFDDF9F2), Color(0xFFF5FFFC)];
      case StudentMoodTheme.sunsetCoral:
        return isDark
            ? const [Color(0xFF271418), Color(0xFF3A1F27)]
            : const [Color(0xFFFFF1F0), Color(0xFFFFE4DE), Color(0xFFFFF8F5)];
      case StudentMoodTheme.midnightPurple:
        return isDark
            ? const [Color(0xFF141026), Color(0xFF211A3A)]
            : const [Color(0xFFF5F2FF), Color(0xFFEAE4FF), Color(0xFFFBF9FF)];
    }
  }
}
