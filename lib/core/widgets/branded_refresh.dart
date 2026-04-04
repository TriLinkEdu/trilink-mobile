import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Branded pull-to-refresh with app primary color theming.
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double edgeOffset;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      strokeWidth: 2.5,
      displacement: 50,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
