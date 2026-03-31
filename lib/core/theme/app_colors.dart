import 'package:flutter/material.dart';

/// Brand constants and legacy UI tokens.
///
/// For student screens, always use `Theme.of(context).colorScheme` so dark
/// mode works automatically. The legacy UI tokens below are kept only for
/// backward compatibility with teacher/parent screens.
class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color accent = Color(0xFFFBBC05);
  static const Color error = Color(0xFFEA4335);

  // Semantic status (brightness-independent)
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC05);
  static const Color info = Color(0xFF1A73E8);

  // Legacy UI tokens — kept for teacher/parent backward compatibility.
  // Student screens should use Theme.of(context).colorScheme instead.
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color divider = Color(0xFFDADCE0);
}
