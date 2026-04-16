import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_names.dart';
import 'features/auth/cubit/auth_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: ListenableBuilder(
        listenable: sl<ThemeNotifier>(),
        builder: (context, _) {
          final tn = sl<ThemeNotifier>();
          final font = tn.fontFamily;
          return MaterialApp(
            title: 'TriLink',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightThemeWith(
              fontFamily: font,
              moodTheme: tn.effectiveMoodTheme,
            ),
            darkTheme: AppTheme.darkThemeWith(
              fontFamily: font,
              moodTheme: tn.effectiveMoodTheme,
            ),
            themeMode: tn.themeMode,
            initialRoute: RouteNames.login,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              final scale = tn.textScaleFactor;
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
