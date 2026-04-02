import 'package:flutter/material.dart';

/// Provides shell-level actions (open drawer, switch tab) to any
/// descendant widget inside the student module's nested navigators.
class StudentShellScope extends InheritedWidget {
  final VoidCallback openDrawer;
  final ValueChanged<int> switchTab;
  final int currentTabIndex;

  const StudentShellScope({
    required this.openDrawer,
    required this.switchTab,
    required this.currentTabIndex,
    required super.child,
    super.key,
  });

  static StudentShellScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<StudentShellScope>();
    assert(scope != null, 'No StudentShellScope found in widget tree');
    return scope!;
  }

  static StudentShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StudentShellScope>();
  }

  @override
  bool updateShouldNotify(StudentShellScope old) =>
      currentTabIndex != old.currentTabIndex;
}
