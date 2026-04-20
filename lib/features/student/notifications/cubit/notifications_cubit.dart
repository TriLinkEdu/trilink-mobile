import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/notification_model.dart';
import '../repositories/student_notifications_repository.dart';
import 'notifications_state.dart';

export 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final StudentNotificationsRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 20);

  NotificationsCubit(this._repository) : super(const NotificationsState());

  Future<void> loadIfNeeded() async {
    if (state.status == NotificationsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final items = await _repository.fetchNotifications();
      emit(
        NotificationsState(status: NotificationsStatus.loaded, items: items),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: 'Unable to load notifications.',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      emit(
        state.copyWith(
          items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: 'Unable to mark all as read.',
        ),
      );
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _repository.markAsRead(id);
      emit(
        state.copyWith(
          items: state.items.map((n) {
            if (n.id == id) return n.copyWith(isRead: true);
            return n;
          }).toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: 'Unable to mark notification as read.',
        ),
      );
    }
  }

  Future<void> toggleRead(NotificationModel notification) async {
    final targetRead = !notification.isRead;
    try {
      if (targetRead) {
        await _repository.markAsRead(notification.id);
      } else {
        await _repository.markAsUnread(notification.id);
      }
      emit(
        state.copyWith(
          items: state.items.map((n) {
            if (n.id == notification.id) {
              return n.copyWith(isRead: targetRead);
            }
            return n;
          }).toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationsStatus.error,
          errorMessage: 'Unable to update notification status.',
        ),
      );
    }
  }
}
