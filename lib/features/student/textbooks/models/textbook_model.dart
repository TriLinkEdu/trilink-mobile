import '../../../../core/constants/api_constants.dart';

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
    if (sizeBytes == null || sizeBytes! <= 0) {
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

  String get resolvedAccessUrl {
    final trimmedAccessUrl = accessUrl.trim();
    if (trimmedAccessUrl.startsWith('http://') ||
        trimmedAccessUrl.startsWith('https://')) {
      return trimmedAccessUrl;
    }
    if (trimmedAccessUrl.startsWith('/')) {
      return '${ApiConstants.fileBaseUrl}/api$trimmedAccessUrl';
    }
    if (fileRecordId.trim().isNotEmpty) {
      return '${ApiConstants.fileBaseUrl}/api${ApiConstants.fileAccess(fileRecordId)}';
    }
    return trimmedAccessUrl;
  }

  factory TextbookModel.fromJson(Map<String, dynamic> json) {
    final file = json['file'];
    final fileMap = file is Map<String, dynamic> ? file : null;

    return TextbookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      grade: (() {
        final rawGrade = json['grade'];
        if (rawGrade is int) return rawGrade;
        if (rawGrade is num) return rawGrade.toInt();
        return int.tryParse(rawGrade?.toString() ?? '') ?? 0;
      })(),
      description: json['description'] as String?,
      pageCount: json['pageCount'] as int?,
      sizeBytes: (() {
        final raw = json['sizeBytes'] ?? fileMap?['sizeBytes'] ?? fileMap?['size'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        final parsed = int.tryParse(raw?.toString() ?? '');
        if (parsed != null) return parsed;

        final sizeText = raw?.toString().trim() ?? '';
        final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*(KB|MB|GB|B)', caseSensitive: false)
            .firstMatch(sizeText);
        if (match == null) return null;
        final value = double.tryParse(match.group(1) ?? '');
        if (value == null) return null;
        final unit = (match.group(2) ?? 'B').toUpperCase();
        switch (unit) {
          case 'KB':
            return (value * 1024).round();
          case 'MB':
            return (value * 1024 * 1024).round();
          case 'GB':
            return (value * 1024 * 1024 * 1024).round();
          default:
            return value.round();
        }
      })(),
      isActive: json['isActive'] as bool,
      fileRecordId: (json['fileRecordId'] ?? '').toString(),
      fileVersion: json['fileVersion']?.toString(),
      fileEtag: json['fileEtag']?.toString(),
      cacheKey: (json['cacheKey'] ?? '${json['fileRecordId'] ?? ''}:v1')
          .toString(),
      accessUrl: (() {
        final raw = json['accessUrl'] ?? json['url'] ?? json['fileUrl'] ?? fileMap?['url'] ?? fileMap?['fileUrl'] ?? fileMap?['accessUrl'];
        return raw?.toString() ?? '';
      })(),
      coverUrl: (() {
        final raw = json['coverUrl'] ?? json['thumbnailUrl'] ?? fileMap?['coverUrl'] ?? fileMap?['thumbnailUrl'];
        final value = raw?.toString().trim() ?? '';
        return value.isEmpty ? null : value;
      })(),
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
