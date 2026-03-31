import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/notification_model.dart';
import '../repositories/student_notifications_repository.dart';
import 'notifications_state.dart';

export 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final StudentNotificationsRepository _repository;

  NotificationsCubit(this._repository) : super(const NotificationsState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final items = await _repository.fetchNotifications();
      emit(NotificationsState(status: NotificationsStatus.loaded, items: items));
    } catch (_) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Unable to load notifications.',
      ));
    }
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    emit(state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
    ));
  }

  Future<void> markNotificationRead(String id) async {
    await _repository.markAsRead(id);
    emit(state.copyWith(
      items: state.items.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList(),
    ));
  }

  Future<void> toggleRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _repository.markAsRead(notification.id);
    }
    emit(state.copyWith(
      items: state.items.map((n) {
        if (n.id == notification.id) {
          return n.copyWith(isRead: !notification.isRead);
        }
        return n;
      }).toList(),
    ));
  }
}
