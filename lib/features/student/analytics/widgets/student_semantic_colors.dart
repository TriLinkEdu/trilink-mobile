import 'package:flutter/material.dart';

class StudentSemanticColors {
  StudentSemanticColors._();

  static const Color info = Color(0xFF2F8FFF);
  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFD48806);
  static const Color risk = Color(0xFFD64545);

  static Color tint(Color color) => color.withAlpha(18);
}
