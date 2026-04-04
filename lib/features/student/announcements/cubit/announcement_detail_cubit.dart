import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_announcements_repository.dart';
import 'announcement_detail_state.dart';

export 'announcement_detail_state.dart';

class AnnouncementDetailCubit extends Cubit<AnnouncementDetailState> {
  final StudentAnnouncementsRepository _repository;
  final String announcementId;

  AnnouncementDetailCubit(this._repository, this.announcementId)
      : super(const AnnouncementDetailState());

  Future<void> loadAnnouncement() async {
    emit(state.copyWith(status: AnnouncementDetailStatus.loading));
    try {
      final all = await _repository.fetchAnnouncements();
      final match = all.where((a) => a.id == announcementId);
      if (match.isNotEmpty) {
        emit(AnnouncementDetailState(
          status: AnnouncementDetailStatus.loaded,
          announcement: match.first,
        ));
      } else {
        emit(state.copyWith(
          status: AnnouncementDetailStatus.error,
          errorMessage: 'Announcement not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
