import '../models/exam_model.dart';
import 'student_exams_repository.dart';

class MockStudentExamsRepository implements StudentExamsRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  int _attemptCounter = 0;
  final List<ExamAttemptModel> _attempts = [];

  static final List<ExamModel> _exams = [
    ExamModel(
      id: 'e1',
      title: 'Calculus Midterm',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      durationMinutes: 60,
      scheduledAt: DateTime.now().add(const Duration(days: 5)),
      questions: const [
        QuestionModel(
          id: 'e1q1',
          text: 'What is the derivative of x²?',
          options: ['x', '2x', '2', 'x²'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e1q2',
          text: 'What is ∫2x dx?',
          options: ['x²', 'x² + C', '2x²', '2x² + C'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e1q3',
          text: 'The limit of sin(x)/x as x→0 is:',
          options: ['0', '∞', '1', 'undefined'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'e1q4',
          text: 'Which rule is used for d/dx[f(g(x))]?',
          options: ['Product rule', 'Quotient rule', 'Chain rule', 'Power rule'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'e1q5',
          text: 'What is the derivative of ln(x)?',
          options: ['x', '1/x', 'ln(x)/x', 'e^x'],
          correctIndex: 1,
        ),
      ],
    ),
    ExamModel(
      id: 'e2',
      title: 'Physics: Mechanics Quiz',
      subjectId: 'physics',
      subjectName: 'Physics',
      durationMinutes: 30,
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      questions: const [
        QuestionModel(
          id: 'e2q1',
          text: 'Newton\'s first law is also known as the law of:',
          options: ['Acceleration', 'Inertia', 'Gravity', 'Momentum'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e2q2',
          text: 'F = ma is which of Newton\'s laws?',
          options: ['First', 'Second', 'Third', 'Fourth'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e2q3',
          text: 'What is the SI unit of force?',
          options: ['Joule', 'Watt', 'Newton', 'Pascal'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'e2q4',
          text: 'Acceleration due to gravity on Earth is approximately:',
          options: ['8.9 m/s²', '9.8 m/s²', '10.8 m/s²', '11.2 m/s²'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e2q5',
          text: 'Kinetic energy is given by:',
          options: ['mv', '½mv²', 'mgh', 'mv²'],
          correctIndex: 1,
        ),
      ],
    ),
    ExamModel(
      id: 'e3',
      title: 'Literature: Romantic Period',
      subjectId: 'literature',
      subjectName: 'Literature',
      durationMinutes: 45,
      scheduledAt: DateTime.now().add(const Duration(days: 10)),
      questions: const [
        QuestionModel(
          id: 'e3q1',
          text: 'Who wrote "I Wandered Lonely as a Cloud"?',
          options: ['Keats', 'Shelley', 'Wordsworth', 'Byron'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'e3q2',
          text: 'The Romantic period emphasized:',
          options: ['Reason and logic', 'Emotion and nature', 'Urban life', 'Scientific method'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e3q3',
          text: 'Which work is by Mary Shelley?',
          options: ['Dracula', 'Frankenstein', 'Wuthering Heights', 'Jane Eyre'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'e3q4',
          text: '"Ode to a Nightingale" was written by:',
          options: ['Wordsworth', 'Byron', 'Keats', 'Coleridge'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'e3q5',
          text: 'Which is NOT a characteristic of Romantic literature?',
          options: ['Love of nature', 'Individualism', 'Strict formalism', 'Supernatural elements'],
          correctIndex: 2,
        ),
      ],
    ),
  ];

  @override
  Future<List<ExamModel>> fetchAvailableExams() async {
    await Future<void>.delayed(_latency);
    return _exams
        .map((e) => ExamModel(
              id: e.id,
              title: e.title,
              subjectId: e.subjectId,
              subjectName: e.subjectName,
              durationMinutes: e.durationMinutes,
              scheduledAt: e.scheduledAt,
              isCompleted: e.isCompleted,
              score: e.score,
              questions: const [],
            ))
        .toList();
  }

  @override
  Future<ExamModel> fetchExamQuestions(String examId) async {
    await Future<void>.delayed(_latency);
    return _exams.firstWhere((e) => e.id == examId);
  }

  @override
  Future<ExamResultModel> submitExam(
    String examId,
    Map<String, int> answers,
  ) async {
    await Future<void>.delayed(_latency);
    final exam = _exams.firstWhere((e) => e.id == examId);
    int correct = 0;
    for (final question in exam.questions) {
      if (answers[question.id] == question.correctIndex) {
        correct++;
      }
    }
    final total = exam.questions.length;
    final percentage = total > 0 ? (correct / total) * 100 : 0.0;
    final xp = (percentage * 0.5).round();

    final idx = _exams.indexWhere((e) => e.id == examId);
    if (idx != -1) {
      _exams[idx] = _exams[idx].copyWith(
        isCompleted: true,
        score: percentage,
      );
    }

    return ExamResultModel(
      examId: exam.id,
      examTitle: exam.title,
      totalQuestions: total,
      correctAnswers: correct,
      score: percentage,
      xpEarned: xp,
      answerMap: answers,
    );
  }

  @override
  Future<ExamAttemptModel> startAttempt(String examId, String studentId) async {
    await Future<void>.delayed(_latency);
    _exams.firstWhere((e) => e.id == examId);
    _attemptCounter++;
    final attempt = ExamAttemptModel(
      id: 'attempt-$_attemptCounter',
      examId: examId,
      studentId: studentId,
      startedAt: DateTime.now(),
      answers: const {},
    );
    _attempts.add(attempt);
    return attempt;
  }

  @override
  Future<ExamAttemptModel> submitAttempt(
    String attemptId,
    Map<String, int> answers,
  ) async {
    await Future<void>.delayed(_latency);
    final idx = _attempts.indexWhere((a) => a.id == attemptId);
    if (idx == -1) {
      throw StateError('Attempt not found: $attemptId');
    }
    final attempt = _attempts[idx];
    final exam = _exams.firstWhere((e) => e.id == attempt.examId);
    int correct = 0;
    for (final question in exam.questions) {
      if (answers[question.id] == question.correctIndex) {
        correct++;
      }
    }
    final total = exam.questions.length;
    final percentage = total > 0 ? (correct / total) * 100 : 0.0;
    final completedAt = DateTime.now();
    final timeSpentSeconds = completedAt.difference(attempt.startedAt).inSeconds;
    final updated = ExamAttemptModel(
      id: attempt.id,
      examId: attempt.examId,
      studentId: attempt.studentId,
      startedAt: attempt.startedAt,
      completedAt: completedAt,
      timeSpentSeconds: timeSpentSeconds,
      answers: answers,
      score: percentage,
    );
    _attempts[idx] = updated;
    return updated;
  }
}
