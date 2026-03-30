import 'package:flutter/material.dart';
import '../../exams/models/exam_model.dart';

class QuizResultScreen extends StatelessWidget {
  final ExamResultModel result;
  final List<QuestionModel>? questions;

  const QuizResultScreen({
    super.key,
    required this.result,
    this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = result.percentage;
    final passed = pct >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(
              passed ? Icons.celebration_rounded : Icons.sentiment_neutral_rounded,
              size: 64,
              color: passed ? Colors.amber : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'Great job!' : 'Keep practicing!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _ScoreCircle(percentage: pct, theme: theme),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  label: 'Correct',
                  value: '${result.correctAnswers}',
                  color: Colors.green,
                ),
                _StatCard(
                  label: 'Wrong',
                  value: '${result.totalQuestions - result.correctAnswers}',
                  color: Colors.red,
                ),
                _StatCard(
                  label: 'XP Earned',
                  value: '+${result.xpEarned}',
                  color: Colors.amber,
                ),
              ],
            ),
            if (questions != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Question Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...questions!.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                final selected = result.answerMap[q.id];
                final isCorrect = selected == q.correctIndex;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCorrect ? Colors.green : Colors.red,
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    title: Text('Q${idx + 1}: ${q.text}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      isCorrect
                          ? 'Correct: ${q.options[q.correctIndex]}'
                          : 'Your answer: ${selected != null ? q.options[selected] : "Skipped"}\nCorrect: ${q.options[q.correctIndex]}',
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double percentage;
  final ThemeData theme;
  const _ScoreCircle({required this.percentage, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 60
            ? Colors.orange
            : Colors.red;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Center(
            child: Text(
              '${percentage.round()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
