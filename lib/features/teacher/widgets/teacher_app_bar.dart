import 'package:flutter/material.dart';

/// Helper widget to create consistent AppBars for teacher screens
/// 
/// Usage:
/// - For top-level screens: Use [TeacherAppBar.drawer] to show menu icon
/// - For detail screens: Use [TeacherAppBar.back] to show back button
class TeacherAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showDrawer;
  final VoidCallback? onDrawerTap;
  final Color? backgroundColor;
  final double elevation;

  const TeacherAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.showDrawer = false,
    this.onDrawerTap,
    this.backgroundColor,
    this.elevation = 0,
  });

  /// Creates an AppBar with drawer/menu icon for top-level screens
  factory TeacherAppBar.drawer({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    required VoidCallback onDrawerTap,
    Color? backgroundColor,
    double elevation = 0,
  }) {
    return TeacherAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      bottom: bottom,
      showDrawer: true,
      onDrawerTap: onDrawerTap,
      backgroundColor: backgroundColor,
      elevation: elevation,
    );
  }

  /// Creates an AppBar with back button for detail/sub screens
  factory TeacherAppBar.back({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Color? backgroundColor,
    double elevation = 0,
  }) {
    return TeacherAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      bottom: bottom,
      showDrawer: false,
      backgroundColor: backgroundColor,
      elevation: elevation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: elevation,
      leading: showDrawer
          ? IconButton(
              icon: Icon(
                Icons.menu,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: onDrawerTap,
              tooltip: 'Menu',
            )
          : IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
