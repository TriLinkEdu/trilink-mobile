import 'package:flutter/material.dart';

abstract final class AppShadows {
  static List<BoxShadow> subtle(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withAlpha(8),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> card(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withAlpha(12),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColor.withAlpha(6),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> elevated(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withAlpha(18),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: shadowColor.withAlpha(8),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glow(Color accentColor) => [
        BoxShadow(
          color: accentColor.withAlpha(40),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
