import '../constants/api_constants.dart';

/// Feature flags for controlling app behavior
///
/// Use these flags to toggle between mock data and real API calls
/// without changing UI code.
class FeatureFlags {
  FeatureFlags._();

  /// Source of truth lives in [ApiConstants.useRealApi]
  /// Made non-const to allow tests to override at runtime.
  static bool useRealApi = ApiConstants.useRealApi;

  /// Set to true to show debug info in UI (like data source indicator)
  static bool showDebugInfo = true;

  /// Set to true to enable verbose logging
  static bool verboseLogging = false;

  /// Set to true to simulate slow network (adds delay to API calls)
  static bool simulateSlowNetwork = true;

  /// Network delay in milliseconds (only if simulateSlowNetwork is true)
  static int networkDelayMs = 1000;

  /// Set to true to enable offline mode testing
  static bool offlineMode = false;

  /// Print current configuration
  static void printConfig() {
    print('═══════════════════════════════════════');
    print('Feature Flags Configuration:');
    print('  useRealApi: $useRealApi');
    print('  showDebugInfo: $showDebugInfo');
    print('  verboseLogging: $verboseLogging');
    print('  simulateSlowNetwork: $simulateSlowNetwork');
    print('  networkDelayMs: $networkDelayMs');
    print('  offlineMode: $offlineMode');
    print('═══════════════════════════════════════');
  }
}
