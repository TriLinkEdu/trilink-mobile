import 'package:equatable/equatable.dart';
import '../models/announcement_model.dart';

enum AnnouncementDetailStatus { initial, loading, loaded, error }

class AnnouncementDetailState extends Equatable {
  final AnnouncementDetailStatus status;
  final AnnouncementModel? announcement;
  final String? errorMessage;

  const AnnouncementDetailState({
    this.status = AnnouncementDetailStatus.initial,
    this.announcement,
    this.errorMessage,
  });

  AnnouncementDetailState copyWith({
    AnnouncementDetailStatus? status,
    AnnouncementModel? announcement,
    String? errorMessage,
  }) {
    return AnnouncementDetailState(
      status: status ?? this.status,
      announcement: announcement ?? this.announcement,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, announcement, errorMessage];
}
