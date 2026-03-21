import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/routes/app_router.dart';
import 'features/auth/screens/login_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _themeNotifier = ThemeNotifier.instance;

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TriLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeNotifier.themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const LoginScreen(),
    );
  }
}
