import '../models/textbook_model.dart';

abstract class TextbookRepository {
  Future<List<TextbookModel>> fetchTextbooks({String? subject, int? grade});
  Future<TextbookModel?> fetchTextbookById(String id);
}
