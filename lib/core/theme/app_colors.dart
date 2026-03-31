import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette ──
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Semantic Status ──
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);

  // ── Gamification Accents ──
  static const Color xpGold = Color(0xFFFFB800);
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color levelPurple = Color(0xFF8B5CF6);
  static const Color achievementEmerald = Color(0xFF10B981);
  static const Color leaderboardCrown = Color(0xFFFBBF24);

  // ── Subject Accents ──
  static const Color mathematics = Color(0xFF3B82F6);
  static const Color physics = Color(0xFF6366F1);
  static const Color literature = Color(0xFFEC4899);
  static const Color history = Color(0xFFF97316);
  static const Color computerScience = Color(0xFF14B8A6);
  static const Color biology = Color(0xFF22C55E);

  static Color subjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus')) return mathematics;
    if (lower.contains('phys')) return physics;
    if (lower.contains('liter') || lower.contains('english')) return literature;
    if (lower.contains('hist')) return history;
    if (lower.contains('comput') || lower.contains('cs')) return computerScience;
    if (lower.contains('bio')) return biology;
    return primary;
  }

  // ── Custom Light Surfaces ──
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceDim = Color(0xFFF1F5F9);

  // ── Custom Dark Surfaces (warm slate, not pure black) ──
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceBright = Color(0xFF334155);

  // ── Legacy Compat (teacher/parent) ──
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color divider = Color(0xFFDADCE0);
}

/// Centralized gradient definitions.
class AppGradients {
  AppGradients._();

  static const LinearGradient primaryHero = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streak = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xp = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFFD166)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient level = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient achievement = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerLight = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
  );

  static const LinearGradient shimmerDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF1E293B)],
  );

  static LinearGradient glassLight = LinearGradient(
    colors: [
      Colors.white.withAlpha(180),
      Colors.white.withAlpha(120),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassDark = LinearGradient(
    colors: [
      Colors.white.withAlpha(15),
      Colors.white.withAlpha(8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
