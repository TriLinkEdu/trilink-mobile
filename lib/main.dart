import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'core/di/injection_container.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register Syncfusion license
  // Get your free license at: https://www.syncfusion.com/account/register
  SyncfusionLicense.registerLicense('YOUR_SYNCFUSION_LICENSE_KEY_HERE');
  
  await initDependencies();
  runApp(const App());
}
