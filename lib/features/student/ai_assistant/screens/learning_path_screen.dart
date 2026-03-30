import 'package:flutter/material.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/mock_student_ai_assistant_repository.dart';
import '../repositories/student_ai_assistant_repository.dart';

/// Generate personalized subject learning paths; export as PDF.
class LearningPathScreen extends StatefulWidget {
  final List<LearningPathItemModel>? items;
  final StudentAiAssistantRepository? repository;

  const LearningPathScreen({super.key, this.items, this.repository});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late final StudentAiAssistantRepository _repository;
  List<LearningPathItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentAiAssistantRepository();
    if (widget.items != null && widget.items!.isNotEmpty) {
      _items = List.of(widget.items!);
    } else {
      _loadFromRepository();
    }
  }

  Future<void> _loadFromRepository() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchAssistantData();
      if (!mounted) return;
      setState(() => _items = List.of(data.learningPath));
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markComplete(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        progress: 1.0,
        isActive: false,
      );
    });
    Navigator.of(context).pop();
  }

  void _showItemDetail(int index) {
    final item = _items[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${item.subject}'),
            const SizedBox(height: 4),
            Text('Duration: ${item.duration}'),
            const SizedBox(height: 4),
            Text('Progress: ${(item.progress * 100).toInt()}%'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (item.progress < 1.0)
            FilledButton(
              onPressed: () => _markComplete(index),
              child: const Text('Mark as Complete'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No learning path items available.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _LearningStepCard(
                      title: item.title,
                      subtitle: '${item.subject} • ${item.duration}',
                      isActive: item.isActive,
                      isComplete: item.progress >= 1.0,
                      onTap: () => _showItemDetail(index),
                    );
                  },
                ),
    );
  }
}

class _LearningStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isComplete;
  final VoidCallback onTap;

  const _LearningStepCard({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isComplete
              ? Icons.check_circle_rounded
              : isActive
                  ? Icons.play_circle_fill_rounded
                  : Icons.menu_book_rounded,
          color: isComplete ? Colors.green : null,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          isComplete
              ? 'Done'
              : isActive
                  ? 'Continue'
                  : 'Start',
          style: TextStyle(
            color: isComplete
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
