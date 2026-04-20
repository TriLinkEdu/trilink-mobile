import 'package:equatable/equatable.dart';

enum StudentSettingsStatus { initial, loading, loaded, error }

class StudentSettingsState extends Equatable {
  final StudentSettingsStatus status;
  final String language;
  final bool notificationsEnabled;
  final bool biometricLock;
  final String? errorMessage;

  const StudentSettingsState({
    this.status = StudentSettingsStatus.initial,
    this.language = 'English',
    this.notificationsEnabled = true,
    this.biometricLock = false,
    this.errorMessage,
  });

  StudentSettingsState copyWith({
    StudentSettingsStatus? status,
    String? language,
    bool? notificationsEnabled,
    bool? biometricLock,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StudentSettingsState(
      status: status ?? this.status,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricLock: biometricLock ?? this.biometricLock,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toSettingsJson() {
    return {
      'language': language,
      'pushNotifications': notificationsEnabled,
      'biometricLock': biometricLock,
    };
  }

  @override
  List<Object?> get props => [
    status,
    language,
    notificationsEnabled,
    biometricLock,
    errorMessage,
  ];
}
