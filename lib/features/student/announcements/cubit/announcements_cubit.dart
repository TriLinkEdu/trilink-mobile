import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_announcements_repository.dart';
import 'announcements_state.dart';

export 'announcements_state.dart';

class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  final StudentAnnouncementsRepository _repository;
  DateTime? _lastLoadedAt;

  /// Timestamp of the most recent successful network refresh, or null if data
  /// has never loaded from the network in this session.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  static const Duration _ttl = Duration(minutes: 15);

  AnnouncementsCubit(this._repository) : super(const AnnouncementsState());

  Future<void> loadIfNeeded() async {
    if (state.status == AnnouncementsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }

    final cached = _repository.getCached();
    if (cached != null) {
      if (state.status != AnnouncementsStatus.loaded) {
        emit(AnnouncementsState(
          status: AnnouncementsStatus.loaded,
          announcements: cached,
        ));
      }
      unawaited(_silentRefresh());
      return;
    }

    await loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    emit(state.copyWith(status: AnnouncementsStatus.loading));
    try {
      final announcements = await _repository.fetchAnnouncements();
      emit(AnnouncementsState(
        status: AnnouncementsStatus.loaded,
        announcements: announcements,
      ));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      final msg = e.toString();
      debugPrint('[AnnouncementsCubit] loadAnnouncements failed: $msg');
      emit(state.copyWith(
        status: AnnouncementsStatus.error,
        errorMessage: msg.contains('ApiException')
            ? msg.replaceFirst('ApiException', 'Error')
            : 'Unable to load announcements right now.',
      ));
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final announcements = await _repository.fetchAnnouncements();
      if (!isClosed) {
        emit(AnnouncementsState(
          status: AnnouncementsStatus.loaded,
          announcements: announcements,
        ));
        _lastLoadedAt = DateTime.now();
      }
    } catch (_) {}
  }
}
