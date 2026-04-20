import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_announcements_repository.dart';
import 'announcements_state.dart';

export 'announcements_state.dart';

class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  final StudentAnnouncementsRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 30);

  AnnouncementsCubit(this._repository) : super(const AnnouncementsState());

  Future<void> loadIfNeeded() async {
    if (state.status == AnnouncementsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    emit(state.copyWith(status: AnnouncementsStatus.loading));
    try {
      final announcements = await _repository.fetchAnnouncements();
      emit(
        AnnouncementsState(
          status: AnnouncementsStatus.loaded,
          announcements: announcements,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: AnnouncementsStatus.error,
          errorMessage: 'Unable to load announcements right now.',
        ),
      );
    }
  }
}
