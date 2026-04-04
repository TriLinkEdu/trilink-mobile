import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static StorageService? _instance;

  factory StorageService([Box? box]) {
    if (_instance == null) {
      if (box == null) {
        throw StateError('StorageService requires a Hive Box on first init.');
      }
      _instance = StorageService._internal(box);
    }
    return _instance!;
  }

  StorageService._internal(this._box);

  final Box _box;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'user_json';
  static const _keyRole = 'current_role';

  // Generic API (from student branch)
  Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  String? getString(String key) {
    return _box.get(key) as String?;
  }

  Future<void> setBool(String key, bool value) async {
    await _box.put(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _box.get(key, defaultValue: defaultValue) as bool? ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _box.put(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _box.get(key, defaultValue: defaultValue) as int? ?? defaultValue;
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  // Auth API (from main branch)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_keyAccessToken, accessToken);
    await _box.put(_keyRefreshToken, refreshToken);
  }

  Future<String?> get accessToken async => _box.get(_keyAccessToken) as String?;

  Future<String?> get refreshToken async => _box.get(_keyRefreshToken) as String?;

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _box.put(_keyUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = _box.get(_keyUser) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveRole(String role) async {
    await _box.put(_keyRole, role);
  }

  Future<String?> getRole() async => _box.get(_keyRole) as String?;

  Future<void> clearAll() async {
    await _box.delete(_keyAccessToken);
    await _box.delete(_keyRefreshToken);
    await _box.delete(_keyUser);
    await _box.delete(_keyRole);
  }

  Future<bool> get hasTokens async => (await accessToken) != null;
}