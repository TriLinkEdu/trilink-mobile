import 'package:equatable/equatable.dart';
import '../models/announcement_model.dart';

enum AnnouncementsStatus { initial, loading, loaded, error }

class AnnouncementsState extends Equatable {
  final AnnouncementsStatus status;
  final List<AnnouncementModel> announcements;
  final String? errorMessage;

  const AnnouncementsState({
    this.status = AnnouncementsStatus.initial,
    this.announcements = const [],
    this.errorMessage,
  });

  AnnouncementsState copyWith({
    AnnouncementsStatus? status,
    List<AnnouncementModel>? announcements,
    String? errorMessage,
  }) {
    return AnnouncementsState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, announcements, errorMessage];
}
