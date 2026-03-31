enum QuestionType { multipleChoice, trueFalse, shortAnswer }

class QuestionModel {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final int correctIndex;
  final double pointValue;

  const QuestionModel({
    required this.id,
    required this.text,
    this.type = QuestionType.multipleChoice,
    required this.options,
    required this.correctIndex,
    this.pointValue = 1.0,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'] as int,
      pointValue: (json['pointValue'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type.name,
        'options': options,
        'correctIndex': correctIndex,
        'pointValue': pointValue,
      };
}

enum ExamLifecycleState { draft, published, active, completed, archived }

class ExamModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final int durationMinutes;
  final List<QuestionModel> questions;
  final DateTime? scheduledAt;
  final bool isCompleted;
  final double? score;
  final ExamLifecycleState lifecycleState;
  final bool isTimeLimited;

  const ExamModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.durationMinutes,
    required this.questions,
    this.scheduledAt,
    this.isCompleted = false,
    this.score,
    this.lifecycleState = ExamLifecycleState.published,
    this.isTimeLimited = true,
  });

  bool get canAttempt =>
      lifecycleState == ExamLifecycleState.published ||
      lifecycleState == ExamLifecycleState.active;

  double get totalPoints =>
      questions.fold(0.0, (sum, q) => sum + q.pointValue);

  ExamModel copyWith({
    String? id,
    String? title,
    String? subjectId,
    String? subjectName,
    int? durationMinutes,
    List<QuestionModel>? questions,
    DateTime? scheduledAt,
    bool? isCompleted,
    double? score,
    ExamLifecycleState? lifecycleState,
    bool? isTimeLimited,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questions: questions ?? this.questions,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      isTimeLimited: isTimeLimited ?? this.isTimeLimited,
    );
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble(),
      lifecycleState: ExamLifecycleState.values.firstWhere(
        (s) => s.name == json['lifecycleState'],
        orElse: () => ExamLifecycleState.published,
      ),
      isTimeLimited: json['isTimeLimited'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'durationMinutes': durationMinutes,
        'questions': questions.map((q) => q.toJson()).toList(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'score': score,
        'lifecycleState': lifecycleState.name,
        'isTimeLimited': isTimeLimited,
      };
}

class ExamAttemptModel {
  final String id;
  final String examId;
  final String studentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final Map<String, int> answers;
  final double? score;

  const ExamAttemptModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.startedAt,
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.answers = const {},
    this.score,
  });

  bool get isFinished => completedAt != null;

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json) {
    return ExamAttemptModel(
      id: json['id'] as String,
      examId: json['examId'] as String,
      studentId: json['studentId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      answers: Map<String, int>.from(json['answers'] ?? {}),
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'studentId': studentId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'timeSpentSeconds': timeSpentSeconds,
        'answers': answers,
        'score': score,
      };
}

class ExamResultModel {
  final String examId;
  final String examTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final int xpEarned;
  final Map<String, int> answerMap;

  const ExamResultModel({
    required this.examId,
    required this.examTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.xpEarned,
    required this.answerMap,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    return ExamResultModel(
      examId: json['examId'] as String,
      examTitle: json['examTitle'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      score: (json['score'] as num).toDouble(),
      xpEarned: json['xpEarned'] as int,
      answerMap: Map<String, int>.from(json['answerMap'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'examTitle': examTitle,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'score': score,
        'xpEarned': xpEarned,
        'answerMap': answerMap,
      };
}
