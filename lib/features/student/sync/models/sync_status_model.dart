enum SyncItemStatus { synced, pending, error }

class SyncItemModel {
  final String id;
  final String category;
  final String description;
  final SyncItemStatus status;
  final DateTime lastSyncedAt;
  final int pendingCount;

  const SyncItemModel({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.lastSyncedAt,
    required this.pendingCount,
  });

  SyncItemModel copyWith({
    String? id,
    String? category,
    String? description,
    SyncItemStatus? status,
    DateTime? lastSyncedAt,
    int? pendingCount,
  }) {
    return SyncItemModel(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }

  factory SyncItemModel.fromJson(Map<String, dynamic> json) {
    return SyncItemModel(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      status: SyncItemStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SyncItemStatus.pending,
      ),
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      pendingCount: json['pendingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'description': description,
        'status': status.name,
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
        'pendingCount': pendingCount,
      };
}
