import 'package:equatable/equatable.dart';
import '../models/sync_status_model.dart';

enum SyncStatus { initial, loading, loaded, error }

class SyncState extends Equatable {
  final SyncStatus status;
  final List<SyncItemModel> items;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    List<SyncItemModel>? items,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
