import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/announcement_model.dart';
import 'student_announcements_repository.dart';

class RealStudentAnnouncementsRepository
    implements StudentAnnouncementsRepository {
  final ApiClient _api;

  RealStudentAnnouncementsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
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
