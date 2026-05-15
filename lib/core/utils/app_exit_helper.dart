import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppExitHelper {
  const AppExitHelper._();

  static Future<void> exitApp() async {
    if (kIsWeb) return;
    await SystemNavigator.pop();
  }
}
