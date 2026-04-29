import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/download_progress_model.dart';

class DownloadProgressState {
  final Map<String, DownloadProgress> downloads;

  DownloadProgressState({
    this.downloads = const {},
  });

  DownloadProgress? getDownload(String id) => downloads[id];

  bool isDownloading(String id) => downloads[id]?.isDownloading ?? false;

  DownloadProgressState copyWith({
    Map<String, DownloadProgress>? downloads,
  }) {
    return DownloadProgressState(
      downloads: downloads ?? this.downloads,
    );
  }
}

class DownloadProgressCubit extends Cubit<DownloadProgressState> {
  DownloadProgressCubit() : super(DownloadProgressState());

  /// Register a new download and emit initial state
  void startDownload({
    required String id,
    required String name,
    required int totalBytes,
  }) {
    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads[id] = DownloadProgress(
      id: id,
      name: name,
      status: DownloadStatus.downloading,
      downloadedBytes: 0,
      totalBytes: totalBytes,
      startedAt: DateTime.now(),
    );
    emit(state.copyWith(downloads: downloads));
  }

  /// Update progress of an ongoing download
  void updateProgress({
    required String id,
    required int downloadedBytes,
  }) {
    final progress = state.downloads[id];
    if (progress == null) return;

    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads[id] = progress.copyWith(downloadedBytes: downloadedBytes);
    emit(state.copyWith(downloads: downloads));
  }

  /// Mark a download as completed
  void completeDownload(String id) {
    final progress = state.downloads[id];
    if (progress == null) return;

    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads[id] = progress.copyWith(status: DownloadStatus.completed);
    emit(state.copyWith(downloads: downloads));
  }

  /// Mark a download as failed
  void failDownload({
    required String id,
    required String errorMessage,
  }) {
    final progress = state.downloads[id];
    if (progress == null) return;

    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads[id] = progress.copyWith(
      status: DownloadStatus.failed,
      errorMessage: errorMessage,
    );
    emit(state.copyWith(downloads: downloads));
  }

  /// Cancel a download
  void cancelDownload(String id) {
    final progress = state.downloads[id];
    if (progress == null) return;

    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads[id] = progress.copyWith(status: DownloadStatus.cancelled);
    emit(state.copyWith(downloads: downloads));
  }

  /// Remove a completed/failed download from tracking
  void removeDownload(String id) {
    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads.remove(id);
    emit(state.copyWith(downloads: downloads));
  }

  /// Clear all completed downloads
  void clearCompleted() {
    final downloads = Map<String, DownloadProgress>.from(state.downloads);
    downloads.removeWhere((_, progress) => progress.isCompleted);
    emit(state.copyWith(downloads: downloads));
  }
}
