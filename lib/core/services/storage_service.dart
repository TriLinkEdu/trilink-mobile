class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Map<String, dynamic> _store = {};

  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  String? getString(String key) {
    return _store[key] as String?;
  }

  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _store[key] as bool? ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    _store[key] = value;
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _store[key] as int? ?? defaultValue;
  }

  Future<void> remove(String key) async {
    _store.remove(key);
  }

  Future<void> clear() async {
    _store.clear();
  }
}
