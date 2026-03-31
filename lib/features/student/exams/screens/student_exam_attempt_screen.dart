import 'package:flutter/material.dart';

class StudentExamAttemptScreen extends StatefulWidget {
  const StudentExamAttemptScreen({super.key});

  @override
  State<StudentExamAttemptScreen> createState() => _StudentExamAttemptScreenState();
}

class _StudentExamAttemptScreenState extends State<StudentExamAttemptScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOption;

  static const _questions = [
    {
      'question': 'What is 7 × 6?',
      'options': ['36', '42', '48', '56'],
      'answer': 1,
    },
    {
      'question': 'Water boils at?',
      'options': ['90°C', '95°C', '100°C', '120°C'],
      'answer': 2,
    },
  ];

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exam submitted (mock).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _questions[_currentQuestionIndex];
    final options = (current['options'] as List<String>);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Attempt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              current['question'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...List.generate(options.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedOption,
                title: Text(options[index]),
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value;
                  });
                },
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOption == null ? null : _nextQuestion,
                child: Text(
                  _currentQuestionIndex == _questions.length - 1
                      ? 'Submit Exam'
                      : 'Next Question',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
