import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/gamification_models.dart';

class BadgeVisuals {
  BadgeVisuals._();

  static IconData iconForBadge(String badgeId) {
    return iconForBadgeMeta(badgeId, null);
  }

  static IconData iconForBadgeMeta(String? key, String? iconKey) {
    final token = (iconKey ?? key ?? '').toLowerCase();
    if (token.contains('attendance') || token.contains('calendar')) {
      return Icons.calendar_month_rounded;
    }
    if (token.contains('exam') || token.contains('quiz') || token.contains('trophy')) {
      return Icons.emoji_events_rounded;
    }
    if (token.contains('streak') || token.contains('fire')) {
      return Icons.local_fire_department_rounded;
    }
    if (token.contains('translate') || token.contains('language')) {
      return Icons.translate_rounded;
    }
    if (token.contains('science') || token.contains('lab')) return Icons.science_rounded;
    if (token.contains('group') || token.contains('team')) return Icons.groups_rounded;
    if (token.contains('star')) return Icons.stars_rounded;
    if (token.contains('ribbon')) return Icons.military_tech_rounded;
    if (token.contains('target')) return Icons.track_changes_rounded;
    if (token.contains('first') || token.contains('welcome')) return Icons.flag_rounded;
    if (token.contains('perfect') || token.contains('100')) return Icons.stars_rounded;
    if (token.contains('master') || token.contains('expert') || token.contains('school')) {
      return Icons.school_rounded;
    }
    if (token.contains('shield') || token.contains('top')) return Icons.shield_rounded;
    if (token.contains('explorer') || token.contains('explore')) return Icons.explore_rounded;
    if (token.contains('legend') || token.contains('premium')) {
      return Icons.workspace_premium_rounded;
    }
    return Icons.workspace_premium_rounded;
  }

  /// Resolve icon for a full [AchievementModel] — uses title keywords then category.
  static IconData iconForAchievement(AchievementModel achievement) {
    final title = achievement.title.toLowerCase();
    if (title.contains('first') || title.contains('welcome') || title.contains('start')) {
      return Icons.flag_rounded;
    }
    if (title.contains('perfect') || title.contains('100%')) return Icons.stars_rounded;
    if (title.contains('week') || title.contains('streak')) {
      return Icons.local_fire_department_rounded;
    }
    if (title.contains('exam') || title.contains('test') || title.contains('taker')) {
      return Icons.emoji_events_rounded;
    }
    if (title.contains('badge') || title.contains('collector')) {
      return Icons.military_tech_rounded;
    }
    if (title.contains('century') || title.contains('power') || title.contains('points')) {
      return Icons.bolt_rounded;
    }
    return _iconForCategory(achievement.category);
  }

  /// Resolve icon when only the achievement ID (UUID) is available.
  /// Prefer [iconForAchievement] when the full model is available.
  static IconData iconForAchievementId(String achievementId) {
    return Icons.emoji_events_rounded;
  }

  static IconData _iconForCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.consistency:
        return Icons.local_fire_department_rounded;
      case AchievementCategory.mastery:
        return Icons.military_tech_rounded;
      case AchievementCategory.social:
        return Icons.handshake_rounded;
      case AchievementCategory.exploration:
        return Icons.travel_explore_rounded;
      case AchievementCategory.milestone:
        return Icons.verified_rounded;
    }
  }

  static Color accentForAchievement(
    AchievementModel achievement,
    ThemeData theme,
  ) {
    if (!achievement.isUnlocked) return theme.colorScheme.onSurfaceVariant;
    switch (achievement.category) {
      case AchievementCategory.consistency:
        return AppColors.streakFire;
      case AchievementCategory.mastery:
        return AppColors.leaderboardCrown;
      case AchievementCategory.social:
        return AppColors.secondary;
      case AchievementCategory.exploration:
        return theme.colorScheme.primary;
      case AchievementCategory.milestone:
        return AppColors.success;
    }
  }
}
