class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
      };
}

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
  });

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
