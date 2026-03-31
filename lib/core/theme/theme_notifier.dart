import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _themeKey = 'themeMode';
  static const _scaleKey = 'textScale';
  static const _fontKey = 'fontFamily';

  static const List<String> availableFonts = [
    'Roboto',
    'Inter',
    'Poppins',
    'Nunito',
    'Lato',
    'Open Sans',
    'Merriweather',
    'Source Code Pro',
  ];

  static const Map<String, double> scaleOptions = {
    'Small': 0.85,
    'Default': 1.0,
    'Large': 1.15,
    'Extra Large': 1.3,
  };

  final StorageService _storage;

  ThemeNotifier(this._storage) {
    final stored = _storage.getString(_themeKey);
    _themeMode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final storedScale = _storage.getString(_scaleKey);
    _textScaleLabel = (storedScale != null && scaleOptions.containsKey(storedScale))
        ? storedScale
        : 'Default';

    final storedFont = _storage.getString(_fontKey);
    _fontFamily = (storedFont != null && availableFonts.contains(storedFont))
        ? storedFont
        : 'Roboto';
  }

  static late ThemeNotifier instance;

  // ── Theme Mode ──

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _storage.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setLight() {
    if (_themeMode == ThemeMode.light) return;
    _themeMode = ThemeMode.light;
    _storage.setString(_themeKey, 'light');
    notifyListeners();
  }

  void setDark() {
    if (_themeMode == ThemeMode.dark) return;
    _themeMode = ThemeMode.dark;
    _storage.setString(_themeKey, 'dark');
    notifyListeners();
  }

  // ── Text Scale ──

  String _textScaleLabel = 'Default';
  String get textScaleLabel => _textScaleLabel;
  double get textScaleFactor => scaleOptions[_textScaleLabel] ?? 1.0;

  void setTextScale(String label) {
    if (!scaleOptions.containsKey(label) || _textScaleLabel == label) return;
    _textScaleLabel = label;
    _storage.setString(_scaleKey, label);
    notifyListeners();
  }

  // ── Font Family ──

  String _fontFamily = 'Roboto';
  String get fontFamily => _fontFamily;

  void setFontFamily(String family) {
    if (!availableFonts.contains(family) || _fontFamily == family) return;
    _fontFamily = family;
    _storage.setString(_fontKey, family);
    notifyListeners();
  }
}
