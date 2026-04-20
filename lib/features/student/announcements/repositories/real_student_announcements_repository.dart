import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/announcement_model.dart';
import 'student_announcements_repository.dart';

class RealStudentAnnouncementsRepository
    implements StudentAnnouncementsRepository {
  final ApiClient _api;

  static List<AnnouncementModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<AnnouncementModel>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 30);

  RealStudentAnnouncementsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    if (_inFlight != null) return _inFlight!;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return data;
  }

  Future<List<AnnouncementModel>> _fetchFresh() async {
    final list = await _api.getList(ApiConstants.announcementsForMe);

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (raw) => AnnouncementModel(
            id: (raw['id'] ?? '').toString(),
            title: (raw['title'] ?? 'Announcement').toString(),
            body: (raw['body'] ?? '').toString(),
            authorName: 'TriLink',
            authorRole: 'Admin',
            createdAt:
                DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
                DateTime.now(),
            category: (raw['audience'] ?? '').toString(),
          ),
        )
        .toList();
  }
}
