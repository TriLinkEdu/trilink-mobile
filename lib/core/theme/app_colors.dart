import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette ──
  static const Color primary = Color(0xFF0F6FFF);
  static const Color primaryLight = Color(0xFF5DA2FF);
  static const Color primaryDark = Color(0xFF0A4FB8);
  static const Color secondary = Color(0xFF00B894);
  static const Color accent = Color(0xFFFF8A00);
  static const Color error = Color(0xFFEF4444);

  // ── Semantic Status ──
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);

  // ── Gamification Accents ──
  static const Color xpGold = Color(0xFFFFC53D);
  static const Color streakFire = Color(0xFFFF6A3D);
  static const Color levelPurple = Color(0xFF3B82F6);
  static const Color achievementEmerald = Color(0xFF10B981);
  static const Color leaderboardCrown = Color(0xFFFBBF24);

  // ── Rank / Medal Accents ──
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  // ── Announcement Category Tints ──
  static const Color categoryGeneral = Color(0xFFDBEAFE);
  static const Color categoryUrgent = Color(0xFFFEE2E2);
  static const Color categoryEvent = Color(0xFFFEF3C7);

  // ── Subject Accents ──
  static const Color mathematics = Color(0xFF2F80ED);
  static const Color physics = Color(0xFF00A6FB);
  static const Color literature = Color(0xFFE76F51);
  static const Color history = Color(0xFFF4A261);
  static const Color computerScience = Color(0xFF00B894);
  static const Color biology = Color(0xFF43AA8B);
  static const Color chemistry = Color(0xFF9B59B6);

  // Generic subject accent colors used by parent/teacher dashboards and lists.
  static const Color subjectPurple = Color(0xFF8B5CF6);
  static const Color subjectOrange = Color(0xFFF97316);
  static const Color subjectTeal = Color(0xFF14B8A6);
  static const Color subjectPink = Color(0xFFEC4899);

  static Color subjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus')) {
      return mathematics;
    }
    if (lower.contains('phys')) {
      return physics;
    }
    if (lower.contains('chem')) {
      return chemistry;
    }
    if (lower.contains('liter') || lower.contains('english')) {
      return literature;
    }
    if (lower.contains('hist')) {
      return history;
    }
    if (lower.contains('comput') || lower.contains('cs')) {
      return computerScience;
    }
    if (lower.contains('bio')) {
      return biology;
    }
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
    colors: [Color(0xFF2B8CFF), Color(0xFF3CB7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streak = LinearGradient(
    colors: [Color(0xFFFF6A3D), Color(0xFFFF9F5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xp = LinearGradient(
    colors: [Color(0xFFFFC53D), Color(0xFFFFDF80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient level = LinearGradient(
    colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient achievement = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient attendance = LinearGradient(
    colors: [Color(0xFF3A97FF), Color(0xFF74BBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmDark = LinearGradient(
    colors: [Color(0xFF0B1220), Color(0xFF172437)],
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
    colors: [Colors.white.withAlpha(180), Colors.white.withAlpha(120)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassDark = LinearGradient(
    colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
