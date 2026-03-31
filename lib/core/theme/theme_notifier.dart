import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _key = 'themeMode';
  final StorageService _storage;

  ThemeNotifier(this._storage) {
    final stored = _storage.getString(_key);
    if (stored == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  /// Provides a static accessor for widgets that need quick reads
  /// without going through DI (e.g., the App widget's ListenableBuilder).
  static late ThemeNotifier instance;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _persist();
    notifyListeners();
  }

  void setLight() {
    if (_themeMode == ThemeMode.light) return;
    _themeMode = ThemeMode.light;
    _persist();
    notifyListeners();
  }

  void setDark() {
    if (_themeMode == ThemeMode.dark) return;
    _themeMode = ThemeMode.dark;
    _persist();
    notifyListeners();
  }

  void _persist() {
    _storage.setString(_key, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
