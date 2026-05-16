import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single source of truth for subject color + icon mapping across the app.
///
/// Accepts either a subject id (e.g. `mathematics`, `computer_science`) or a
/// human-readable subject name (e.g. `Mathematics`, `English Literature`).
/// Lookups are case-insensitive and use fuzzy substring matching so the
/// helper is resilient to different backend naming conventions.
class SubjectVisuals {
  const SubjectVisuals._();

  /// Returns the brand color associated with the given subject.
  static Color colorOf(String subject) {
    final key = _normalize(subject);
    if (key.contains('math') || key.contains('calculus') || key.contains('algebra')) {
      return AppColors.mathematics;
    }
    if (key.contains('phys') || key.contains('mechanic')) {
      return AppColors.physics;
    }
    if (key.contains('chem')) {
      return AppColors.chemistry;
    }
    if (key.contains('bio')) {
      return AppColors.biology;
    }
    if (key.contains('liter') || key.contains('english') || key.contains('language')) {
      return AppColors.literature;
    }
    if (key.contains('hist') || key.contains('social')) {
      return AppColors.history;
    }
    if (key.contains('comput') || key.contains('cs') || key.contains('program') || key.contains('coding')) {
      return AppColors.computerScience;
    }
    return AppColors.primary;
  }

  /// Returns the icon associated with the given subject.
  static IconData iconOf(String subject) {
    final key = _normalize(subject);
    if (key.contains('math') || key.contains('calculus') || key.contains('algebra')) {
      return Icons.calculate_rounded;
    }
    if (key.contains('phys') || key.contains('mechanic')) {
      return Icons.science_rounded;
    }
    if (key.contains('chem')) {
      return Icons.biotech_rounded;
    }
    if (key.contains('bio')) {
      return Icons.eco_rounded;
    }
    if (key.contains('liter') || key.contains('english') || key.contains('language')) {
      return Icons.auto_stories_rounded;
    }
    if (key.contains('hist') || key.contains('social')) {
      return Icons.history_edu_rounded;
    }
    if (key.contains('comput') || key.contains('cs') || key.contains('program') || key.contains('coding')) {
      return Icons.computer_rounded;
    }
    return Icons.school_rounded;
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll('_', ' ').trim();
}
