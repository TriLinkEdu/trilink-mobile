import '../../../../core/models/curriculum_models.dart';

abstract class StudentCurriculumRepository {
  Future<List<SubjectModel>> fetchSubjects();
  Future<List<TopicModel>> fetchTopics(String subjectId);

  List<SubjectModel>? getCached() => null;
  void clearCache() {}
}
