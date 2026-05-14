import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/feedback_model.dart';
import 'student_feedback_repository.dart';

class RealStudentFeedbackRepository implements StudentFeedbackRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static List<FeedbackModel> _localHistory = const [];
  static DateTime? _historyFetchedAt;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentFeedbackRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<FeedbackModel>> fetchFeedbackHistory() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
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
      await _persistCache(userId);
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
    await _persistCache(await _currentUserId());
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

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_feedback_v1'
      : 'student_feedback_v1_$userId';

  void _restoreCache(String userId) {
    if (_localHistory.isNotEmpty) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! List) return;
    _localHistory = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(FeedbackModel.fromJson)
        .toList();
    _historyFetchedAt = entry.savedAt;
  }

  Future<void> _persistCache(String userId) async {
    await _cacheService.write(
      _cacheKey(userId),
      _localHistory.map((item) => item.toJson()).toList(),
    );
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
