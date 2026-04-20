import 'dart:convert';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import 'student_settings_repository.dart';

class RealStudentSettingsRepository implements StudentSettingsRepository {
  final ApiClient _api;

  static Map<String, dynamic>? _cache;
  static DateTime? _fetchedAt;
  static Future<Map<String, dynamic>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentSettingsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<Map<String, dynamic>> fetchSettings() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return Map<String, dynamic>.from(_cache!);
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final payload = jsonEncode(settings);
    await _api.patch(
      ApiConstants.userSettings,
      data: {'settingsJson': payload},
    );
    _cache = Map<String, dynamic>.from(settings);
    _fetchedAt = DateTime.now();
  }

  Future<Map<String, dynamic>> _fetchFresh() async {
    final raw = await _api.get(ApiConstants.userSettings);
    final settingsJson = (raw['settingsJson'] ?? '{}').toString();
    try {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
}
