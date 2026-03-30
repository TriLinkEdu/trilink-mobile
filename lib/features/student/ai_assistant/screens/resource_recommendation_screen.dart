import 'package:flutter/material.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/mock_student_ai_assistant_repository.dart';
import '../repositories/student_ai_assistant_repository.dart';

/// Curated list of PDFs, videos, and other study resources.
class ResourceRecommendationScreen extends StatefulWidget {
  final List<ResourceRecommendationModel>? resources;
  final StudentAiAssistantRepository? repository;

  const ResourceRecommendationScreen({
    super.key,
    this.resources,
    this.repository,
  });

  @override
  State<ResourceRecommendationScreen> createState() =>
      _ResourceRecommendationScreenState();
}

class _ResourceRecommendationScreenState
    extends State<ResourceRecommendationScreen> {
  late final StudentAiAssistantRepository _repository;
  List<ResourceRecommendationModel> _resources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentAiAssistantRepository();
    if (widget.resources != null && widget.resources!.isNotEmpty) {
      _resources = List.of(widget.resources!);
    } else {
      _loadFromRepository();
    }
  }

  Future<void> _loadFromRepository() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchAssistantData();
      if (!mounted) return;
      setState(() => _resources = List.of(data.resources));
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openResource(ResourceRecommendationModel resource) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened ${resource.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resources.isEmpty
              ? const Center(child: Text('No resources available.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _resources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final resource = _resources[index];
                    final icon = switch (resource.type.toLowerCase()) {
                      'video' => Icons.ondemand_video_rounded,
                      'worksheet' => Icons.assignment_rounded,
                      'article' => Icons.article_rounded,
                      _ => Icons.menu_book_rounded,
                    };

                    return _ResourceTile(
                      title: resource.title,
                      subtitle:
                          '${resource.type} • ${resource.estimatedTime} • ${resource.level}',
                      icon: icon,
                      onOpen: () => _openResource(resource),
                    );
                  },
                ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onOpen;

  const _ResourceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: onOpen,
          child: const Text('Open'),
        ),
      ),
    );
  }
}
