import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

enum AppFeedback { achievement, messageSent, refresh, tap, levelUp }

/// Haptic feedback service that provides tactile feedback patterns.
/// Manages a user-toggleable preference persisted via [StorageService].
class SoundService extends ChangeNotifier {
  static const _storageKey = 'haptic_feedback_enabled';

  final StorageService? _storage;
  bool _enabled;

  SoundService([this._storage])
      : _enabled = _storage?.getBool(_storageKey) ?? true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      _storage?.setBool(_storageKey, value);
      notifyListeners();
    }
  }

  void toggle() => setEnabled(!_enabled);

  void play(AppFeedback feedback) {
    if (!_enabled) return;

    switch (feedback) {
      case AppFeedback.achievement:
        HapticFeedback.heavyImpact();
      case AppFeedback.messageSent:
        HapticFeedback.lightImpact();
      case AppFeedback.refresh:
        HapticFeedback.selectionClick();
      case AppFeedback.tap:
        HapticFeedback.selectionClick();
      case AppFeedback.levelUp:
        HapticFeedback.heavyImpact();
    }
  }
}
