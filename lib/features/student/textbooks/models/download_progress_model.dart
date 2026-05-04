import 'package:equatable/equatable.dart';

enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadProgress extends Equatable {
  final String id;
  final String name;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime startedAt;
  final String? errorMessage;

  const DownloadProgress({
    required this.id,
    required this.name,
    required this.status,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.startedAt,
    this.errorMessage,
  });

  /// Returns progress percentage (0-100)
  double get progressPercentage {
    if (totalBytes <= 0) return 0;
    return (downloadedBytes / totalBytes).clamp(0, 1) * 100;
  }

  /// Returns formatted progress string (e.g., "2.3MB / 5.1MB")
  String get formattedProgress {
    return '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';
  }

  /// Returns elapsed time
  Duration get elapsedTime => DateTime.now().difference(startedAt);

  /// Calculates estimated remaining time based on current speed
  Duration? get estimatedRemainingTime {
    if (progressPercentage == 0 || elapsedTime.inSeconds < 1) return null;
    
    final bytesPerSecond = downloadedBytes / elapsedTime.inSeconds;
    if (bytesPerSecond <= 0) return null;
    
    final remainingBytes = totalBytes - downloadedBytes;
    final remainingSeconds = remainingBytes / bytesPerSecond;
    
    return Duration(seconds: remainingSeconds.toInt());
  }

  /// Returns formatted estimated time string (e.g., "5 min 30 sec")
  String get formattedEstimatedTime {
    final remaining = estimatedRemainingTime;
    if (remaining == null) return 'Calculating...';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Returns download speed (e.g., "1.2 MB/s")
  String get downloadSpeed {
    if (elapsedTime.inSeconds < 1) return '0 MB/s';
    
    final bytesPerSecond = downloadedBytes / elapsedTime.inSeconds;
    final mbPerSecond = bytesPerSecond / (1024 * 1024);
    
    if (mbPerSecond < 0.01) {
      final kbPerSecond = bytesPerSecond / 1024;
      return '${kbPerSecond.toStringAsFixed(1)} KB/s';
    }
    return '${mbPerSecond.toStringAsFixed(1)} MB/s';
  }

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;

  DownloadProgress copyWith({
    String? id,
    String? name,
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    DateTime? startedAt,
    String? errorMessage,
  }) {
    return DownloadProgress(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      startedAt: startedAt ?? this.startedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final index = (bytes.toString().length - 1) ~/ 3;
    final value = bytes / (1000 * (1 << (index * 10)));
    return '${value.toStringAsFixed(1)} ${suffixes[index]}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        downloadedBytes,
        totalBytes,
        startedAt,
        errorMessage,
      ];
}
