import '../../../../core/network/api_client.dart';
import '../../textbooks/models/textbook_model.dart';
import '../../textbooks/repositories/textbook_repository.dart';
import '../models/course_resource_model.dart';
import 'student_courses_repository.dart';

class RealStudentCoursesRepository implements StudentCoursesRepository {
  final ApiClient _api;
  final TextbookRepository _textbooks;
  final StudentCoursesRepository _fallback;

  static const Duration _ttl = Duration(seconds: 30);

  static List<CourseResourceModel>? _resourcesCache;
  static DateTime? _resourcesFetchedAt;
  static Future<List<CourseResourceModel>>? _resourcesInFlight;

  RealStudentCoursesRepository({
    ApiClient? apiClient,
    required TextbookRepository textbooksRepository,
    required StudentCoursesRepository fallback,
  }) : _api = apiClient ?? ApiClient(),
       _textbooks = textbooksRepository,
       _fallback = fallback;

  @override
  Future<List<CourseResourceModel>> fetchCourseResources() async {
    if (_resourcesCache != null && _resourcesFetchedAt != null) {
      final age = DateTime.now().difference(_resourcesFetchedAt!);
      if (age < _ttl) return _resourcesCache!;
    }

    final inFlight = _resourcesInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _resourcesInFlight = future;
    final data = await future;
    _resourcesInFlight = null;
    _resourcesCache = data;
    _resourcesFetchedAt = DateTime.now();
    return data;
  }

  @override
  Future<List<CourseResourceModel>> fetchResourcesBySubject(
    String subjectId,
  ) async {
    final all = await fetchCourseResources();
    final normalized = subjectId.trim().toLowerCase();
    return all
        .where((r) => r.subjectId.trim().toLowerCase() == normalized)
        .toList();
  }

  @override
  Future<CourseResourceModel?> fetchResourceById(String resourceId) async {
    final all = await fetchCourseResources();
    for (final resource in all) {
      if (resource.id == resourceId) return resource;
    }
    return null;
  }

  Future<List<CourseResourceModel>> _fetchFresh() async {
    List<CourseResourceModel> teacherResources = const [];
    List<CourseResourceModel> textbookResources = const [];

    try {
      final teacherRows = await _api.getList('/course-resources/me');
      teacherResources = teacherRows
          .whereType<Map<String, dynamic>>()
          .map(_mapTeacherResource)
          .toList();
    } catch (_) {
      teacherResources = await _fallback.fetchCourseResources();
    }

    try {
      final textbooks = await _textbooks.fetchTextbooks();
      textbookResources = textbooks.map(_mapTextbookResource).toList();
    } catch (_) {
      textbookResources = const [];
    }

    final merged = <CourseResourceModel>[
      ...textbookResources,
      ...teacherResources,
    ];
    merged.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return merged;
  }

  CourseResourceModel _mapTeacherResource(Map<String, dynamic> raw) {
    final subjectId = (raw['subjectId'] ?? raw['subject'] ?? 'general')
        .toString();
    final subjectName = (raw['subjectName'] ?? raw['subject'] ?? 'General')
        .toString();
    final typeRaw = (raw['type'] ?? 'document').toString().toLowerCase();
    final uploadedAt =
        DateTime.tryParse((raw['uploadedAt'] ?? '').toString()) ??
        DateTime.now();

    return CourseResourceModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Resource').toString(),
      subjectId: _normalizeSubjectId(subjectId),
      subjectName: subjectName,
      topicId: raw['topicId']?.toString(),
      type: _parseResourceType(typeRaw),
      description: raw['description']?.toString(),
      url: raw['url']?.toString(),
      fileSize: raw['fileSize']?.toString(),
      uploadedAt: uploadedAt,
    );
  }

  CourseResourceModel _mapTextbookResource(TextbookModel textbook) {
    return CourseResourceModel(
      id: 'textbook-${textbook.id}',
      title: textbook.title,
      subjectId: _normalizeSubjectId(textbook.subject),
      subjectName: textbook.subject,
      type: ResourceType.pdf,
      description: textbook.description,
      url: textbook.accessUrl,
      fileSize: textbook.fileSizeDisplay,
      textbookId: textbook.id,
      textbookFileRecordId: textbook.fileRecordId,
      textbookCacheKey: textbook.cacheKey,
      uploadedAt: textbook.createdAt,
    );
  }

  ResourceType _parseResourceType(String raw) {
    switch (raw) {
      case 'pdf':
        return ResourceType.pdf;
      case 'video':
        return ResourceType.video;
      case 'link':
        return ResourceType.link;
      case 'presentation':
      case 'ppt':
      case 'pptx':
        return ResourceType.presentation;
      default:
        return ResourceType.document;
    }
  }

  String _normalizeSubjectId(String input) {
    return input.trim().toLowerCase().replaceAll(' ', '_');
  }
}
