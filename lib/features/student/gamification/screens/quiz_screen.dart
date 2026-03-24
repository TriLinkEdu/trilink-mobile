import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String subjectId;
  final String? chapterId;

  const QuizScreen({super.key, required this.subjectId, this.chapterId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _score = 0;

  final List<_Question> _questions = const [
    _Question(
      prompt: 'What is the SI unit of force?',
      options: ['Newton', 'Joule', 'Pascal', 'Watt'],
      correctIndex: 0,
    ),
    _Question(
      prompt: 'Acceleration due to gravity on Earth is approximately?',
      options: ['4.9 m/s²', '9.8 m/s²', '19.6 m/s²', '1.6 m/s²'],
      correctIndex: 1,
    ),
  ];

  void _selectAnswer(int index) {
    if (_questionIndex >= _questions.length) {
      return;
    }

    if (index == _questions[_questionIndex].correctIndex) {
      _score += 1;
    }

    setState(() {
      _questionIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _questionIndex >= _questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: finished
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score: $_score / ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _questionIndex = 0;
                        _score = 0;
                      });
                    },
                    child: const Text('Retry Quiz'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_questionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _questions[_questionIndex].prompt,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    _questions[_questionIndex].options.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _selectAnswer(index),
                          child: Text(_questions[_questionIndex].options[index]),
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

class _Question {
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const _Question({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
}
