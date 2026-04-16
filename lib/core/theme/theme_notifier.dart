import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'theme_personalization.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _themeKey = 'themeMode';
  static const _scaleKey = 'textScale';
  static const _fontKey = 'fontFamily';
  static const _moodThemeKey = 'studentMoodTheme';
  static const _textureKey = 'studentTextureStyle';
  static const _autoApplyThemesKey = 'studentAutoApplyThemes';
  static const _scheduleModeKey = 'studentThemeScheduleMode';

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
    _textScaleLabel =
        (storedScale != null && scaleOptions.containsKey(storedScale))
        ? storedScale
        : 'Default';

    final storedFont = _storage.getString(_fontKey);
    _fontFamily = (storedFont != null && availableFonts.contains(storedFont))
        ? storedFont
        : 'Roboto';

    final storedMood = _storage.getString(_moodThemeKey);
    _selectedMoodTheme =
        _moodFromString(storedMood) ?? StudentMoodTheme.focusBlue;

    final storedTexture = _storage.getString(_textureKey);
    _textureStyle = _textureFromString(storedTexture) ?? ThemeTextureStyle.flat;

    _autoApplyThemes = _storage.getBool(
      _autoApplyThemesKey,
      defaultValue: false,
    );

    final storedSchedule = _storage.getString(_scheduleModeKey);
    _scheduleMode =
        _scheduleModeFromString(storedSchedule) ?? ThemeScheduleMode.timeOfDay;

    _applyScheduledThemeIfEnabled();
  }

  static late ThemeNotifier instance;

  // ── Theme Mode ──

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _storage.setString(
      _themeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
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

  StudentMoodTheme _selectedMoodTheme = StudentMoodTheme.focusBlue;
  StudentMoodTheme get selectedMoodTheme => _selectedMoodTheme;

  ThemeTextureStyle _textureStyle = ThemeTextureStyle.flat;
  ThemeTextureStyle get textureStyle => _textureStyle;

  bool _autoApplyThemes = false;
  bool get autoApplyThemes => _autoApplyThemes;

  ThemeScheduleMode _scheduleMode = ThemeScheduleMode.timeOfDay;
  ThemeScheduleMode get scheduleMode => _scheduleMode;

  bool _previewEnabled = false;
  bool get previewEnabled => _previewEnabled;

  StudentMoodTheme? _previewMoodTheme;
  ThemeTextureStyle? _previewTextureStyle;

  StudentMoodTheme get effectiveMoodTheme => _previewEnabled
      ? (_previewMoodTheme ?? _selectedMoodTheme)
      : _selectedMoodTheme;

  ThemeTextureStyle get effectiveTextureStyle =>
      _previewEnabled ? (_previewTextureStyle ?? _textureStyle) : _textureStyle;

  void setSelectedMoodTheme(StudentMoodTheme mood) {
    if (_selectedMoodTheme == mood) return;
    _selectedMoodTheme = mood;
    _storage.setString(_moodThemeKey, mood.name);
    notifyListeners();
  }

  void setTextureStyle(ThemeTextureStyle texture) {
    if (_textureStyle == texture) return;
    _textureStyle = texture;
    _storage.setString(_textureKey, texture.name);
    notifyListeners();
  }

  void setAutoApplyThemes(bool enabled) {
    if (_autoApplyThemes == enabled) return;
    _autoApplyThemes = enabled;
    _storage.setBool(_autoApplyThemesKey, enabled);
    if (_autoApplyThemes) {
      _applyScheduledThemeIfEnabled();
    }
    notifyListeners();
  }

  void setScheduleMode(ThemeScheduleMode mode) {
    if (_scheduleMode == mode) return;
    _scheduleMode = mode;
    _storage.setString(_scheduleModeKey, mode.name);
    if (_autoApplyThemes) {
      _applyScheduledThemeIfEnabled();
    }
    notifyListeners();
  }

  void setPreviewEnabled(bool enabled) {
    _previewEnabled = enabled;
    if (!enabled) {
      _previewMoodTheme = null;
      _previewTextureStyle = null;
    }
    notifyListeners();
  }

  void setPreviewMoodTheme(StudentMoodTheme mood) {
    _previewMoodTheme = mood;
    notifyListeners();
  }

  void setPreviewTextureStyle(ThemeTextureStyle texture) {
    _previewTextureStyle = texture;
    notifyListeners();
  }

  void applyPreview() {
    if (_previewMoodTheme != null) {
      _selectedMoodTheme = _previewMoodTheme!;
      _storage.setString(_moodThemeKey, _selectedMoodTheme.name);
    }
    if (_previewTextureStyle != null) {
      _textureStyle = _previewTextureStyle!;
      _storage.setString(_textureKey, _textureStyle.name);
    }
    _previewEnabled = false;
    _previewMoodTheme = null;
    _previewTextureStyle = null;
    notifyListeners();
  }

  void cancelPreview() {
    _previewEnabled = false;
    _previewMoodTheme = null;
    _previewTextureStyle = null;
    notifyListeners();
  }

  void syncScheduledThemeNow() {
    _applyScheduledThemeIfEnabled();
    notifyListeners();
  }

  StudentMoodTheme? _moodFromString(String? value) {
    if (value == null) return null;
    for (final mood in StudentMoodTheme.values) {
      if (mood.name == value) return mood;
    }
    return null;
  }

  ThemeTextureStyle? _textureFromString(String? value) {
    if (value == null) return null;
    for (final texture in ThemeTextureStyle.values) {
      if (texture.name == value) return texture;
    }
    return null;
  }

  ThemeScheduleMode? _scheduleModeFromString(String? value) {
    if (value == null) return null;
    for (final mode in ThemeScheduleMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  void _applyScheduledThemeIfEnabled() {
    if (!_autoApplyThemes) return;
    if (_scheduleMode == ThemeScheduleMode.timeOfDay) {
      final hour = DateTime.now().hour;
      StudentMoodTheme nextMood;
      if (hour >= 5 && hour < 11) {
        nextMood = StudentMoodTheme.focusBlue;
      } else if (hour >= 11 && hour < 16) {
        nextMood = StudentMoodTheme.energyOrange;
      } else if (hour >= 16 && hour < 20) {
        nextMood = StudentMoodTheme.sunsetCoral;
      } else {
        nextMood = StudentMoodTheme.midnightPurple;
      }
      _selectedMoodTheme = nextMood;
      _storage.setString(_moodThemeKey, nextMood.name);
      _applyMoodBrightnessRule(nextMood);
    }
  }

  void _applyMoodBrightnessRule(StudentMoodTheme mood) {
    final darkPreferred = mood == StudentMoodTheme.midnightPurple;
    final nextMode = darkPreferred ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != nextMode) {
      _themeMode = nextMode;
      _storage.setString(
        _themeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    }
  }
}
