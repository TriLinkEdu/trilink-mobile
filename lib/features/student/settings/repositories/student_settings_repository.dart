abstract class StudentSettingsRepository {
  Future<Map<String, dynamic>> fetchSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
}
