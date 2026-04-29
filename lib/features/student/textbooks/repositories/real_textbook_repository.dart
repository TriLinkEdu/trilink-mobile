import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/textbook_model.dart';
import 'textbook_repository.dart';

class RealTextbookRepository implements TextbookRepository {
  final ApiClient _api;

  RealTextbookRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<TextbookModel>> fetchTextbooks({
    String? subject,
    int? grade,
  }) async {
    final queryParameters =
        <String, dynamic>{'subject': subject, 'grade': grade}..removeWhere((
          key,
          value,
        ) {
          if (value == null) return true;
          if (key == 'subject' && value is String && value.isEmpty) return true;
          return false;
        });
    final rows = await _api.getList(
      ApiConstants.textbooks,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(TextbookModel.fromJson)
        .toList();
  }

  @override
  Future<TextbookModel?> fetchTextbookById(String id) async {
    final response = await _api.get(ApiConstants.textbook(id));
    return TextbookModel.fromJson(response);
  }
}
