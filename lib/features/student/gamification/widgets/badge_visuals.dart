import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/gamification_models.dart';

class BadgeVisuals {
  BadgeVisuals._();

  static IconData iconForBadge(String badgeId) {
    switch (badgeId) {
      case 'badge-addis-attendance':
        return Icons.calendar_month_rounded;
      case 'badge-ethiopian-studies':
        return Icons.menu_book_rounded;
      case 'badge-amharic-english':
        return Icons.translate_rounded;
      case 'badge-national-exam-prep':
        return Icons.track_changes_rounded;
      case 'badge-science-fair':
        return Icons.science_rounded;
      case 'badge-midnight-disciplined':
        return Icons.nights_stay_rounded;
      case 'badge-speed-runner':
        return Icons.bolt_rounded;
      case 'badge-polymath-explorer':
        return Icons.public_rounded;
      case 'badge-class-catalyst':
        return Icons.groups_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  static IconData iconForAchievement(AchievementModel achievement) {
    switch (achievement.id) {
      case 'ach-1':
        return Icons.flag_rounded;
      case 'ach-2':
        return Icons.stars_rounded;
      case 'ach-3':
        return Icons.local_fire_department_rounded;
      case 'ach-4':
        return Icons.school_rounded;
      case 'ach-5':
        return Icons.shield_rounded;
      case 'ach-6':
        return Icons.calendar_month_rounded;
      case 'ach-7':
        return Icons.psychology_alt_rounded;
      case 'ach-8':
        return Icons.groups_rounded;
      case 'ach-9':
        return Icons.explore_rounded;
      case 'ach-10':
        return Icons.workspace_premium_rounded;
      default:
        switch (achievement.category) {
          case AchievementCategory.consistency:
            return Icons.autorenew_rounded;
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
  }

  static IconData iconForAchievementId(String achievementId) {
    switch (achievementId) {
      case 'ach-1':
        return Icons.flag_rounded;
      case 'ach-2':
        return Icons.stars_rounded;
      case 'ach-3':
        return Icons.local_fire_department_rounded;
      case 'ach-4':
        return Icons.school_rounded;
      case 'ach-5':
        return Icons.shield_rounded;
      case 'ach-6':
        return Icons.calendar_month_rounded;
      case 'ach-7':
        return Icons.psychology_alt_rounded;
      case 'ach-8':
        return Icons.groups_rounded;
      case 'ach-9':
        return Icons.explore_rounded;
      case 'ach-10':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
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
