class ExamModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final DateTime scheduledDate;
  final int durationMinutes;
  final List<QuestionModel> questions;
  final String status; // draft, published, completed

  const ExamModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.scheduledDate,
    required this.durationMinutes,
    required this.questions,
    required this.status,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      durationMinutes: json['durationMinutes'] as int,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList(),
      status: json['status'] as String,
    );
  }
}

class QuestionModel {
  final String id;
  final String text;
  final String type; // multiple_choice, short_answer, essay
  final List<String>? options;
  final String? correctAnswer;
  final double points;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.correctAnswer,
    required this.points,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      correctAnswer: json['correctAnswer'] as String?,
      points: (json['points'] as num).toDouble(),
    );
  }
}
