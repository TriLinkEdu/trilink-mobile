import 'dart:convert';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/exam_model.dart';
import 'student_exams_repository.dart';

class RealStudentExamsRepository implements StudentExamsRepository {
  final ApiClient _api;

  RealStudentExamsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<ExamModel>> fetchAvailableExams() async {
    final rows = await _api.getList(ApiConstants.exams);
    final out = <ExamModel>[];
    for (final raw in rows.whereType<Map<String, dynamic>>()) {
      out.add(_mapExamSummary(raw));
    }
    return out;
  }

  @override
  Future<ExamModel> fetchExamQuestions(String examId) async {
    final examRows = await _api.getList(ApiConstants.exams);
    Map<String, dynamic>? examRaw;
    for (final item in examRows.whereType<Map<String, dynamic>>()) {
      if ((item['id'] ?? '').toString() == examId) {
        examRaw = item;
        break;
      }
    }
    final summary = examRaw != null
        ? _mapExamSummary(examRaw)
        : ExamModel(
            id: examId,
            title: 'Exam',
            subjectId: '',
            subjectName: 'Subject',
            durationMinutes: 60,
            questions: const [],
          );

    final rows = await _api.getList(ApiConstants.examQuestions(examId));
    final questions = <QuestionModel>[];
    for (final raw in rows.whereType<Map<String, dynamic>>()) {
      questions.add(_mapQuestion(raw));
    }

    return summary.copyWith(questions: questions);
  }

  @override
  Future<ExamResultModel> submitExam(
    String examId,
    Map<String, int> answers,
  ) async {
    throw UnimplementedError(
      'submitExam requires an active attempt id. Use startAttempt + submitAttempt flow.',
    );
  }

  @override
  Future<ExamAttemptModel> startAttempt(String examId, String studentId) async {
    final raw = await _api.post(ApiConstants.examAttempts(examId));
    return _mapAttempt(raw, examId: examId, studentId: studentId);
  }

  @override
  Future<ExamAttemptModel> submitAttempt(
    String attemptId,
    Map<String, int> answers,
  ) async {
    final payload = <String, String>{'answersJson': _encodeAnswers(answers)};
    final saved = await _api.post(
      ApiConstants.attemptAnswers(attemptId),
      data: payload,
    );
    final submitted = await _api.post(ApiConstants.attemptSubmit(attemptId));
    final merged = <String, dynamic>{...saved, ...submitted};
    return _mapAttempt(merged);
  }

  ExamModel _mapExamSummary(Map<String, dynamic> raw) {
    final opensAt = DateTime.tryParse((raw['opensAt'] ?? '').toString());
    final closesAt = DateTime.tryParse((raw['closesAt'] ?? '').toString());
    final now = DateTime.now();
    final published = raw['published'] == true;

    ExamLifecycleState lifecycle;
    if (!published) {
      lifecycle = ExamLifecycleState.draft;
    } else if (opensAt != null &&
        closesAt != null &&
        now.isAfter(opensAt) &&
        now.isBefore(closesAt)) {
      lifecycle = ExamLifecycleState.active;
    } else if (closesAt != null && now.isAfter(closesAt)) {
      lifecycle = ExamLifecycleState.completed;
    } else {
      lifecycle = ExamLifecycleState.published;
    }

    final title = (raw['title'] ?? 'Exam').toString();
    return ExamModel(
      id: (raw['id'] ?? '').toString(),
      title: title,
      subjectId: (raw['classOfferingId'] ?? '').toString(),
      subjectName: (raw['classOfferingId'] ?? 'Class').toString(),
      durationMinutes: _asInt(raw['durationMinutes'], fallback: 60),
      scheduledAt: opensAt,
      lifecycleState: lifecycle,
      questions: const [],
      isCompleted: lifecycle == ExamLifecycleState.completed,
      isTimeLimited: true,
    );
  }

  QuestionModel _mapQuestion(Map<String, dynamic> raw) {
    final optionsJson = (raw['optionsJson'] ?? '').toString();
    final options = _decodeOptions(optionsJson);

    return QuestionModel(
      id: (raw['questionId'] ?? raw['id'] ?? '').toString(),
      text: (raw['stem'] ?? '').toString(),
      type: _parseQuestionType((raw['type'] ?? 'mcq').toString()),
      options: options,
      correctIndex: -1,
      pointValue: _asDouble(raw['points'], fallback: 1),
    );
  }

  ExamAttemptModel _mapAttempt(
    Map<String, dynamic> raw, {
    String? examId,
    String? studentId,
  }) {
    final startedAt =
        DateTime.tryParse((raw['startedAt'] ?? '').toString()) ??
        DateTime.now();
    final submittedAt = DateTime.tryParse(
      (raw['submittedAt'] ?? '').toString(),
    );
    return ExamAttemptModel(
      id: (raw['id'] ?? '').toString(),
      examId: examId ?? (raw['examId'] ?? '').toString(),
      studentId: studentId ?? (raw['studentId'] ?? '').toString(),
      startedAt: startedAt,
      completedAt: submittedAt,
      answers: const {},
      score: _asNullableDouble(raw['score']),
      timeSpentSeconds: submittedAt == null
          ? 0
          : submittedAt.difference(startedAt).inSeconds,
    );
  }

  List<String> _decodeOptions(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // no-op, fall through
    }
    return const [];
  }

  QuestionType _parseQuestionType(String raw) {
    switch (raw.toLowerCase()) {
      case 'true_false':
      case 'true-false':
        return QuestionType.trueFalse;
      case 'short_answer':
      case 'short-answer':
        return QuestionType.shortAnswer;
      default:
        return QuestionType.multipleChoice;
    }
  }

  String _encodeAnswers(Map<String, int> answers) {
    final payload = <String, String>{};
    for (final entry in answers.entries) {
      payload[entry.key] = entry.value.toString();
    }
    return jsonEncode(payload);
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
