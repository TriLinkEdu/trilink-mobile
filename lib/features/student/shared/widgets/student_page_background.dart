import 'package:flutter/material.dart';

class StudentPageBackground extends StatelessWidget {
  final Widget child;

  const StudentPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A1526), Color(0xFF10263D)]
              : const [Color(0xFFF2FAFF), Color(0xFFE8F5FF), Color(0xFFF7FCFF)],
          stops: isDark ? null : const [0.0, 0.62, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
