/// Feature flags for controlling app behavior
///
/// Use these flags to toggle between mock data and real API calls
/// without changing UI code.
class FeatureFlags {
  FeatureFlags._();

  /// Set to true to use real backend API
  /// Set to false to use dummy/mock data only
  static const bool useRealApi = true;

  /// Set to true to show debug info in UI (like data source indicator)
  static const bool showDebugInfo = true;

  /// Set to true to enable verbose logging
  static const bool verboseLogging = false;

  /// Set to true to simulate slow network (adds delay to API calls)
  static const bool simulateSlowNetwork = false;

  /// Network delay in milliseconds (only if simulateSlowNetwork is true)
  static const int networkDelayMs = 1000;

  /// Set to true to enable offline mode testing
  static const bool offlineMode = false;

  /// Print current configuration
  static void printConfig() {
    print('═══════════════════════════════════════');
    print('Feature Flags Configuration:');
    print('  useRealApi: $useRealApi');
    print('  showDebugInfo: $showDebugInfo');
    print('  verboseLogging: $verboseLogging');
    print('  simulateSlowNetwork: $simulateSlowNetwork');
    print('  offlineMode: $offlineMode');
    print('═══════════════════════════════════════');
  }
}
