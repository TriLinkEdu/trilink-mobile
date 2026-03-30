import 'package:flutter/material.dart';
import '../../exams/models/exam_model.dart';
import '../repositories/student_gamification_repository.dart';
import '../repositories/mock_student_gamification_repository.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String subjectId;
  final String? chapterId;
  final StudentGamificationRepository? repository;

  const QuizScreen({
    super.key,
    required this.subjectId,
    this.chapterId,
    this.repository,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final StudentGamificationRepository _repository;
  ExamModel? _quiz;
  bool _isLoading = true;
  String? _error;

  int _questionIndex = 0;
  final Map<String, int> _answers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentGamificationRepository();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quiz = await _repository.fetchQuiz(widget.subjectId);
      if (!mounted) return;
      setState(() => _quiz = quiz);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load quiz. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(int optionIndex) {
    final quiz = _quiz;
    if (quiz == null || _questionIndex >= quiz.questions.length) return;

    final question = quiz.questions[_questionIndex];
    setState(() {
      _answers[question.id] = optionIndex;
      _questionIndex += 1;
    });

    if (_questionIndex >= quiz.questions.length) {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    final quiz = _quiz;
    if (quiz == null) return;

    setState(() => _submitting = true);
    try {
      final result = await _repository.submitQuizAnswers(quiz.id, _answers);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            result: result,
            questions: quiz.questions,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit quiz. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Quiz not found.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadQuiz,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final quiz = _quiz!;
    final finished = _questionIndex >= quiz.questions.length;

    return Scaffold(
      appBar: AppBar(title: Text(quiz.title)),
      body: _submitting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting your answers...'),
                ],
              ),
            )
          : finished
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (_questionIndex + 1) / quiz.questions.length,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Question ${_questionIndex + 1} of ${quiz.questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        quiz.questions[_questionIndex].text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        quiz.questions[_questionIndex].options.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _selectAnswer(index),
                              child: Text(
                                quiz.questions[_questionIndex].options[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
