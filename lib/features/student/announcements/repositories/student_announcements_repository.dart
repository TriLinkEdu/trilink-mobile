import '../models/announcement_model.dart';

abstract class StudentAnnouncementsRepository {
  Future<List<AnnouncementModel>> fetchAnnouncements();
  List<AnnouncementModel>? getCached() => null;
  void clearCache() {}
}
