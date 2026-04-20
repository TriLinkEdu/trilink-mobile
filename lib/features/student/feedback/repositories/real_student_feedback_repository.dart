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

    try {
      final rows = await _api.getList(ApiConstants.feedbackMe);
      final remote = rows
          .whereType<Map<String, dynamic>>()
          .map(_mapRemote)
          .toList();
      _localHistory = remote;
    } catch (_) {
      // Keep local in-memory history fallback.
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

  FeedbackModel _mapRemote(Map<String, dynamic> raw) {
    final parsed = _parseMessage((raw['message'] ?? '').toString());

    return FeedbackModel(
      id: (raw['id'] ?? '').toString(),
      subjectId: parsed.subjectId,
      subjectName: parsed.subjectName,
      rating: parsed.rating,
      comment: parsed.comment,
      createdAt:
          DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: (raw['status'] ?? 'open').toString(),
    );
  }

  _ParsedFeedback _parseMessage(String message) {
    String subjectName = 'General';
    String subjectId = 'general';
    int rating = 4;
    final comments = <String>[];

    final lines = message.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('subject:')) {
        final value = trimmed.substring(8).trim();
        if (value.isNotEmpty) {
          subjectName = value;
          subjectId = value.toLowerCase().replaceAll(' ', '_');
        }
      } else if (trimmed.toLowerCase().startsWith('rating:')) {
        final digits = RegExp(r'\d+').firstMatch(trimmed)?.group(0);
        final parsed = int.tryParse(digits ?? '');
        if (parsed != null) {
          rating = parsed.clamp(1, 5);
        }
      } else if (trimmed.toLowerCase().startsWith('comment:')) {
        final value = trimmed.substring(8).trim();
        if (value.isNotEmpty) comments.add(value);
      } else if (trimmed.toLowerCase().startsWith('what went well:') ||
          trimmed.toLowerCase().startsWith('could improve:')) {
        comments.add(trimmed);
      }
    }

    return _ParsedFeedback(
      subjectId: subjectId,
      subjectName: subjectName,
      rating: rating,
      comment: comments.isEmpty ? null : comments.join('\n'),
    );
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

class _ParsedFeedback {
  final String subjectId;
  final String subjectName;
  final int rating;
  final String? comment;

  const _ParsedFeedback({
    required this.subjectId,
    required this.subjectName,
    required this.rating,
    required this.comment,
  });
}
