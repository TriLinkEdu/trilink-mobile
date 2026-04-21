import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/storage_service.dart';
import '../repositories/student_settings_repository.dart';
import 'student_settings_state.dart';

class StudentSettingsCubit extends Cubit<StudentSettingsState> {
  final StudentSettingsRepository _repository;
  final StorageService _storage;

  StudentSettingsCubit(this._repository, this._storage)
    : super(const StudentSettingsState());

  Future<void> loadSettings() async {
    emit(
      state.copyWith(status: StudentSettingsStatus.loading, clearError: true),
    );
    try {
      final remote = await _repository.fetchSettings();
      final language =
          (remote['language'] ?? _storage.getString('language') ?? 'English')
              .toString();
      final notifications = _asBool(
        remote['pushNotifications'],
        fallback: _storage.getBool('pushNotifications', defaultValue: true),
      );
      final biometric = _asBool(
        remote['biometricLock'],
        fallback: _storage.getBool('biometricLock'),
      );

      await _storage.setString('language', language);
      await _storage.setBool('pushNotifications', notifications);
      await _storage.setBool('biometricLock', biometric);

      emit(
        state.copyWith(
          status: StudentSettingsStatus.loaded,
          language: language,
          notificationsEnabled: notifications,
          biometricLock: biometric,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StudentSettingsStatus.error,
          errorMessage: 'Unable to load settings from server.',
        ),
      );
    }
  }

  Future<void> setLanguage(String language) async {
    final next = state.copyWith(language: language);
    await _persist(next);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final next = state.copyWith(notificationsEnabled: value);
    await _persist(next);
  }

  Future<void> setBiometricLock(bool value) async {
    final next = state.copyWith(biometricLock: value);
    await _persist(next);
  }

  Future<void> _persist(StudentSettingsState next) async {
    emit(next.copyWith(status: StudentSettingsStatus.loaded, clearError: true));
    await _storage.setString('language', next.language);
    await _storage.setBool('pushNotifications', next.notificationsEnabled);
    await _storage.setBool('biometricLock', next.biometricLock);

    try {
      await _repository.saveSettings(next.toSettingsJson());
    } catch (_) {
      emit(
        next.copyWith(
          status: StudentSettingsStatus.loaded,
          errorMessage: 'Saved locally. Server sync pending.',
        ),
      );
    }
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }
}
