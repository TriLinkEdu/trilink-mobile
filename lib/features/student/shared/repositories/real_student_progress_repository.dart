import '../../../../core/network/api_client.dart';
import '../models/student_progress_model.dart';
import 'student_progress_repository.dart';

class RealStudentProgressRepository implements StudentProgressRepository {
  final ApiClient _api;

  static StudentProgressModel? _cache;
  static DateTime? _fetchedAt;
  static Future<StudentProgressModel>? _inFlight;
  static const Duration _ttl = Duration(seconds: 30);

  RealStudentProgressRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<StudentProgressModel> fetchProgress() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return data;
  }

  Future<StudentProgressModel> _fetchFresh() async {
    final streakData = await _safeGet('/gamification/me/streak');
    final pointsData = await _safeGet('/gamification/me/badge-points');

    final currentStreak = _asInt(streakData['currentStreak'], fallback: 0);
    final longestStreak = _asInt(
      streakData['longestStreak'],
      fallback: currentStreak,
    );
    final totalXp = _asInt(pointsData['totalPoints'], fallback: 0);
    final level = (totalXp ~/ 100).clamp(1, 999);

    return StudentProgressModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalXp: totalXp,
      level: level,
      levelTitle: _levelTitle(level),
    );
  }

  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      return await _api.get(path);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _levelTitle(int level) {
    if (level >= 20) return 'Legend';
    if (level >= 15) return 'Master';
    if (level >= 10) return 'Scholar';
    if (level >= 5) return 'Learner';
    return 'Starter';
  }
}
