import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/feedback_model.dart';
import 'student_feedback_repository.dart';

class RealStudentFeedbackRepository implements StudentFeedbackRepository {
  final ApiClient _api;

  static List<FeedbackModel> _localHistory = const [];
  static DateTime? _historyFetchedAt;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentFeedbackRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<FeedbackModel>> fetchFeedbackHistory() async {
    final fetchedAt = _historyFetchedAt;
    if (fetchedAt != null && DateTime.now().difference(fetchedAt) < _ttl) {
      return _localHistory;
    }
    _historyFetchedAt = DateTime.now();
    return _localHistory;
  }

  @override
  Future<FeedbackModel> submitFeedback({
    required String subjectId,
    required String subjectName,
    required int rating,
    String? comment,
  }) async {
    final payload = {
      'category': 'general',
      'message': _composeMessage(
        subjectName: subjectName,
        rating: rating,
        comment: comment,
      ),
      'isAnonymous': true,
    };

    final raw = await _api.post(ApiConstants.feedback, data: payload);
    final model = FeedbackModel(
      id: (raw['id'] ?? '').toString(),
      subjectId: subjectId,
      subjectName: subjectName,
      rating: rating,
      comment: comment,
      createdAt:
          DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: (raw['status'] ?? 'open').toString(),
    );

    _localHistory = [..._localHistory, model];
    _historyFetchedAt = DateTime.now();
    return model;
  }

  String _composeMessage({
    required String subjectName,
    required int rating,
    String? comment,
  }) {
    final buffer = StringBuffer();
    buffer.write('Subject: $subjectName\n');
    buffer.write('Rating: $rating/5\n');
    if (comment != null && comment.trim().isNotEmpty) {
      buffer.write('Comment: ${comment.trim()}');
    }
    return buffer.toString().trim();
  }
}
