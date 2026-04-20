import 'student_settings_repository.dart';

class MockStudentSettingsRepository implements StudentSettingsRepository {
  Map<String, dynamic> _settings = const <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> fetchSettings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return Map<String, dynamic>.from(_settings);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _settings = Map<String, dynamic>.from(settings);
  }
}
