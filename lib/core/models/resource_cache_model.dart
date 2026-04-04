enum CacheSyncStatus { pending, synced, failed }

class ResourceCacheModel {
  final String id;
  final String studentId;
  final String resourceId;
  final String resourceTitle;
  final String localPath;
  final CacheSyncStatus syncStatus;
  final DateTime lastSyncTimestamp;
  final int retryCount;
  final String? lastError;
  final int sizeBytes;

  const ResourceCacheModel({
    required this.id,
    required this.studentId,
    required this.resourceId,
    required this.resourceTitle,
    required this.localPath,
    this.syncStatus = CacheSyncStatus.pending,
    required this.lastSyncTimestamp,
    this.retryCount = 0,
    this.lastError,
    this.sizeBytes = 0,
  });

  bool get canRetry => retryCount < 5;
  bool get isSynced => syncStatus == CacheSyncStatus.synced;

  ResourceCacheModel copyWith({
    CacheSyncStatus? syncStatus,
    DateTime? lastSyncTimestamp,
    int? retryCount,
    String? lastError,
  }) {
    return ResourceCacheModel(
      id: id,
      studentId: studentId,
      resourceId: resourceId,
      resourceTitle: resourceTitle,
      localPath: localPath,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
      sizeBytes: sizeBytes,
    );
  }

  factory ResourceCacheModel.fromJson(Map<String, dynamic> json) {
    return ResourceCacheModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      resourceId: json['resourceId'] as String,
      resourceTitle: json['resourceTitle'] as String,
      localPath: json['localPath'] as String,
      syncStatus: CacheSyncStatus.values.firstWhere(
        (s) => s.name == json['syncStatus'],
        orElse: () => CacheSyncStatus.pending,
      ),
      lastSyncTimestamp: DateTime.parse(json['lastSyncTimestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'resourceId': resourceId,
        'resourceTitle': resourceTitle,
        'localPath': localPath,
        'syncStatus': syncStatus.name,
        'lastSyncTimestamp': lastSyncTimestamp.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
        'sizeBytes': sizeBytes,
      };
}
