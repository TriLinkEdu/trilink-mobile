import 'package:hive/hive.dart';

class StorageService {
  final Box _box;

  StorageService(this._box);

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
}
