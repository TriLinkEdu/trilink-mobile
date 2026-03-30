import 'package:flutter/material.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/mock_student_ai_assistant_repository.dart';
import '../repositories/student_ai_assistant_repository.dart';

/// AI-generated general feedback about performance and learning habits.
class EvaluateMeScreen extends StatefulWidget {
  final List<EvaluateInsightModel>? insights;
  final StudentAiAssistantRepository? repository;

  const EvaluateMeScreen({super.key, this.insights, this.repository});

  @override
  State<EvaluateMeScreen> createState() => _EvaluateMeScreenState();
}

class _EvaluateMeScreenState extends State<EvaluateMeScreen> {
  late final StudentAiAssistantRepository _repository;
  List<EvaluateInsightModel> _insights = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentAiAssistantRepository();
    if (widget.insights != null && widget.insights!.isNotEmpty) {
      _insights = List.of(widget.insights!);
    } else {
      _loadFromRepository();
    }
  }

  Future<void> _loadFromRepository() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchAssistantData();
      if (!mounted) return;
      setState(() => _insights = List.of(data.insights));
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluate Me')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
              ? const Center(
                  child: Text('No evaluation insights available.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _insights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final insight = _insights[index];
                    return _InsightCard(
                      title: insight.title,
                      summary: insight.summary,
                      recommendation: insight.recommendation,
                    );
                  },
                ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String summary;
  final String recommendation;

  const _InsightCard({
    required this.title,
    required this.summary,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(summary),
            const SizedBox(height: 8),
            Text('Recommendation: $recommendation'),
          ],
        ),
      ),
    );
  }
}
