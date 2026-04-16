import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'theme_personalization.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

// ── ThemeExtension for custom tokens ──

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final LinearGradient heroGradient;
  final LinearGradient streakGradient;
  final LinearGradient xpGradient;
  final LinearGradient levelGradient;
  final LinearGradient shimmerGradient;
  final LinearGradient glassGradient;
  final Color cardBackground;
  final Color cardBorder;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color glassBarrier;

  const AppThemeExtension({
    required this.heroGradient,
    required this.streakGradient,
    required this.xpGradient,
    required this.levelGradient,
    required this.shimmerGradient,
    required this.glassGradient,
    required this.cardBackground,
    required this.cardBorder,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.glassBarrier,
  });

  @override
  AppThemeExtension copyWith({
    LinearGradient? heroGradient,
    LinearGradient? streakGradient,
    LinearGradient? xpGradient,
    LinearGradient? levelGradient,
    LinearGradient? shimmerGradient,
    LinearGradient? glassGradient,
    Color? cardBackground,
    Color? cardBorder,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? glassBarrier,
  }) {
    return AppThemeExtension(
      heroGradient: heroGradient ?? this.heroGradient,
      streakGradient: streakGradient ?? this.streakGradient,
      xpGradient: xpGradient ?? this.xpGradient,
      levelGradient: levelGradient ?? this.levelGradient,
      shimmerGradient: shimmerGradient ?? this.shimmerGradient,
      glassGradient: glassGradient ?? this.glassGradient,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      glassBarrier: glassBarrier ?? this.glassBarrier,
    );
  }

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) {
    if (other == null) return this;
    return AppThemeExtension(
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      streakGradient: LinearGradient.lerp(
        streakGradient,
        other.streakGradient,
        t,
      )!,
      xpGradient: LinearGradient.lerp(xpGradient, other.xpGradient, t)!,
      levelGradient: LinearGradient.lerp(
        levelGradient,
        other.levelGradient,
        t,
      )!,
      shimmerGradient: LinearGradient.lerp(
        shimmerGradient,
        other.shimmerGradient,
        t,
      )!,
      glassGradient: LinearGradient.lerp(
        glassGradient,
        other.glassGradient,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      glassBarrier: Color.lerp(glassBarrier, other.glassBarrier, t)!,
    );
  }
}

// ── Convenience accessor ──

extension ThemeDataExt on ThemeData {
  AppThemeExtension get ext => extension<AppThemeExtension>()!;
}

// ── Theme Builder ──

// ...existing code...
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData lightThemeWith({
    String? fontFamily,
    StudentMoodTheme moodTheme = StudentMoodTheme.focusBlue,
  }) => _build(Brightness.light, fontFamily: fontFamily, moodTheme: moodTheme);
  static ThemeData darkThemeWith({
    String? fontFamily,
    StudentMoodTheme moodTheme = StudentMoodTheme.focusBlue,
  }) => _build(Brightness.dark, fontFamily: fontFamily, moodTheme: moodTheme);

  static ThemeData _build(
    Brightness brightness, {
    String? fontFamily,
    StudentMoodTheme moodTheme = StudentMoodTheme.focusBlue,
  }) {
    final isDark = brightness == Brightness.dark;
    final seedColor = _seedForMood(moodTheme);
    final hero = _heroGradientForMood(moodTheme, isDark);
    final surfaceBase = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryContainer = Color.alphaBlend(
      seedColor.withAlpha(isDark ? 92 : 46),
      surfaceBase,
    );
    final onPrimary = _adaptiveOnColor(seedColor);
    final onPrimaryContainer = _adaptiveOnColor(primaryContainer);

    final baseScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
            surface: AppColors.darkSurface,
            onSurface: const Color(0xFFE2E8F0),
            surfaceContainerLow: const Color(0xFF1A2332),
            surfaceContainer: AppColors.darkSurfaceBright,
            surfaceContainerHighest: const Color(0xFF475569),
            outlineVariant: const Color(0xFF334155),
          )
        : ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
            surface: AppColors.lightSurface,
            surfaceContainerLow: AppColors.lightSurfaceDim,
          );

    final scaffoldBg = _scaffoldBackgroundForMood(seedColor, isDark);

    final colorScheme = baseScheme.copyWith(
      primary: seedColor,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
    );

    final ext = isDark
        ? AppThemeExtension(
            heroGradient: hero,
            streakGradient: AppGradients.streak,
            xpGradient: AppGradients.xp,
            levelGradient: AppGradients.level,
            shimmerGradient: AppGradients.shimmerDark,
            glassGradient: AppGradients.glassDark,
            cardBackground: AppColors.darkSurface,
            cardBorder: const Color(0xFF334155),
            shimmerBase: const Color(0xFF1E293B),
            shimmerHighlight: const Color(0xFF334155),
            glassBarrier: Colors.black54,
          )
        : AppThemeExtension(
            heroGradient: hero,
            streakGradient: AppGradients.streak,
            xpGradient: AppGradients.xp,
            levelGradient: AppGradients.level,
            shimmerGradient: AppGradients.shimmerLight,
            glassGradient: AppGradients.glassLight,
            cardBackground: AppColors.lightSurface,
            cardBorder: Colors.transparent,
            shimmerBase: const Color(0xFFE2E8F0),
            shimmerHighlight: const Color(0xFFF8FAFC),
            glassBarrier: Colors.black26,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.buildTextTheme(
        fontFamily ?? AppTextStyles.defaultFontFamily,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [ext],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(130)),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF334155)
            : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withAlpha(180),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  static Color _adaptiveOnColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static Color _scaffoldBackgroundForMood(Color seedColor, bool isDark) {
    final base = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final alpha = isDark ? 36 : 24;
    return Color.alphaBlend(seedColor.withAlpha(alpha), base);
  }

  static Color _seedForMood(StudentMoodTheme moodTheme) {
    switch (moodTheme) {
      case StudentMoodTheme.focusBlue:
        return const Color(0xFF2F8FFF);
      case StudentMoodTheme.energyOrange:
        return const Color(0xFFF97316);
      case StudentMoodTheme.calmMint:
        return const Color(0xFF14B8A6);
      case StudentMoodTheme.sunsetCoral:
        return const Color(0xFFFF6F61);
      case StudentMoodTheme.midnightPurple:
        return const Color(0xFF7C3AED);
    }
  }

  static LinearGradient _heroGradientForMood(
    StudentMoodTheme moodTheme,
    bool isDark,
  ) {
    switch (moodTheme) {
      case StudentMoodTheme.focusBlue:
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              )
            : const LinearGradient(
                colors: [Color(0xFF2B8CFF), Color(0xFF3CB7FF)],
              );
      case StudentMoodTheme.energyOrange:
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFF8A00), Color(0xFFF97316)],
              );
      case StudentMoodTheme.calmMint:
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
              )
            : const LinearGradient(
                colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
              );
      case StudentMoodTheme.sunsetCoral:
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF9A3412), Color(0xFFBE123C)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFF7E67), Color(0xFFFF5E78)],
              );
      case StudentMoodTheme.midnightPurple:
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
              )
            : const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              );
    }
  }
}
