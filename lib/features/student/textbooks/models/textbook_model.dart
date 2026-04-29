class TextbookModel {
  final String id;
  final String title;
  final String subject;
  final int grade;
  final String? description;
  final int? pageCount;
  final int? sizeBytes;
  final bool isActive;
  final String fileRecordId;
  final String? fileVersion;
  final String? fileEtag;
  final String cacheKey;
  final String accessUrl;
  final String? coverUrl;
  final DateTime createdAt;

  const TextbookModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    this.description,
    this.pageCount,
    this.sizeBytes,
    required this.isActive,
    required this.fileRecordId,
    this.fileVersion,
    this.fileEtag,
    required this.cacheKey,
    required this.accessUrl,
    this.coverUrl,
    required this.createdAt,
  });

  String get fileSizeDisplay {
    if (sizeBytes == null) {
      return 'Unknown size';
    }
    if (sizeBytes! < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes! < 1024 * 1024) {
      return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory TextbookModel.fromJson(Map<String, dynamic> json) {
    return TextbookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      grade: json['grade'] as int,
      description: json['description'] as String?,
      pageCount: json['pageCount'] as int?,
      sizeBytes: (() {
        final raw = json['sizeBytes'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse(raw?.toString() ?? '');
      })(),
      isActive: json['isActive'] as bool,
      fileRecordId: (json['fileRecordId'] ?? '').toString(),
      fileVersion: json['fileVersion']?.toString(),
      fileEtag: json['fileEtag']?.toString(),
      cacheKey: (json['cacheKey'] ?? '${json['fileRecordId'] ?? ''}:v1')
          .toString(),
      accessUrl: json['accessUrl'] as String,
      coverUrl: json['coverUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'grade': grade,
    'description': description,
    'pageCount': pageCount,
    'sizeBytes': sizeBytes,
    'isActive': isActive,
    'fileRecordId': fileRecordId,
    'fileVersion': fileVersion,
    'fileEtag': fileEtag,
    'cacheKey': cacheKey,
    'accessUrl': accessUrl,
    'coverUrl': coverUrl,
    'createdAt': createdAt.toIso8601String(),
  };
}
