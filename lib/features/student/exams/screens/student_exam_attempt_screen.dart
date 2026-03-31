import 'package:flutter/material.dart';
import '../../gamification/screens/quiz_result_screen.dart';
import '../models/exam_model.dart';
import '../repositories/mock_student_exams_repository.dart';
import '../repositories/student_exams_repository.dart';

class StudentExamAttemptScreen extends StatefulWidget {
  final String? examId;
  final StudentExamsRepository? repository;

  const StudentExamAttemptScreen({super.key, this.examId, this.repository});

  @override
  State<StudentExamAttemptScreen> createState() =>
      _StudentExamAttemptScreenState();
}

class _StudentExamAttemptScreenState extends State<StudentExamAttemptScreen> {
  late final StudentExamsRepository _repository =
      widget.repository ?? MockStudentExamsRepository();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  ExamModel? _exam;
  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      ExamModel exam;
      if (widget.examId != null) {
        exam = await _repository.fetchExamQuestions(widget.examId!);
      } else {
        final exams = await _repository.fetchAvailableExams();
        if (exams.isEmpty) throw Exception('No exams available');
        exam = await _repository.fetchExamQuestions(exams.first.id);
      }
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load exam.';
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int optionIndex) {
    final question = _exam!.questions[_currentQuestionIndex];
    setState(() => _answers[question.id] = optionIndex);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _exam!.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.submitExam(_exam!.id, _answers);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            result: result,
            questions: _exam!.questions,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit exam.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Attempt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Attempt')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadExam,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final exam = _exam!;
    final questions = exam.questions;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(exam.title)),
        body: const Center(child: Text('No questions in this exam.')),
      );
    }

    final current = questions[_currentQuestionIndex];
    final selectedOption = _answers[current.id];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(exam.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_answers.length}/${questions.length} answered',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
            ),
            const SizedBox(height: 16),
            Text(
              current.text,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...List.generate(current.options.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: selectedOption,
                title: Text(current.options[index]),
                onChanged: (value) {
                  if (value != null) _selectAnswer(value);
                },
              );
            }),
            const Spacer(),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedOption == null
                        ? null
                        : isLastQuestion
                            ? (_isSubmitting ? null : _submitExam)
                            : _nextQuestion,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastQuestion
                            ? 'Submit Exam'
                            : 'Next Question'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
