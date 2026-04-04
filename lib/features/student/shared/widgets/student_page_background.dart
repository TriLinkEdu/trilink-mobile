import 'package:flutter/material.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/theme/theme_personalization.dart';

class StudentPageBackground extends StatelessWidget {
  final Widget child;

  const StudentPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final texture = ThemeNotifier.instance.effectiveTextureStyle;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0A1526), Color(0xFF10263D)]
                  : const [
                      Color(0xFFF2FAFF),
                      Color(0xFFE8F5FF),
                      Color(0xFFF7FCFF),
                    ],
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
                      ? [Colors.white.withAlpha(4), Colors.black.withAlpha(6)]
                      : [Colors.white.withAlpha(30), Colors.black.withAlpha(4)],
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
                          Theme.of(context).colorScheme.primary.withAlpha(40),
                          Colors.transparent,
                        ]
                      : [
                          Theme.of(context).colorScheme.primary.withAlpha(26),
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
}
