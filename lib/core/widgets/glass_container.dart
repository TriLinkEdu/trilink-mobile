import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// A frosted-glass container for nav bars, modals, and floating cards.
/// Uses BackdropFilter for real blur with semi-transparent surface.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.ext;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.borderLg;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: ext.glassGradient,
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : Colors.white.withAlpha(80),
                  width: 0.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
