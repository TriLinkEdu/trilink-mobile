import '../models/announcement_model.dart';

abstract class StudentAnnouncementsRepository {
  Future<List<AnnouncementModel>> fetchAnnouncements();
}
