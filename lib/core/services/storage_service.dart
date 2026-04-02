import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'user_json';
  static const _keyRole = 'current_role';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final p = await prefs;
    await p.setString(_keyAccessToken, accessToken);
    await p.setString(_keyRefreshToken, refreshToken);
  }

  Future<String?> get accessToken async =>
      (await prefs).getString(_keyAccessToken);

  Future<String?> get refreshToken async =>
      (await prefs).getString(_keyRefreshToken);

  Future<void> saveUser(Map<String, dynamic> user) async {
    (await prefs).setString(_keyUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final json = (await prefs).getString(_keyUser);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> saveRole(String role) async {
    (await prefs).setString(_keyRole, role);
  }

  Future<String?> getRole() async => (await prefs).getString(_keyRole);

  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_keyAccessToken);
    await p.remove(_keyRefreshToken);
    await p.remove(_keyUser);
    await p.remove(_keyRole);
  }

  Future<bool> get hasTokens async => (await accessToken) != null;
}
