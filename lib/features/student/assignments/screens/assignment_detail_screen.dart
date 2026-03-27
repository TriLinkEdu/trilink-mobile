import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../repositories/mock_student_assignments_repository.dart';
import '../repositories/student_assignments_repository.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final StudentAssignmentsRepository? repository;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    this.repository,
  });

  @override
  State<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final StudentAssignmentsRepository _repository =
      widget.repository ?? MockStudentAssignmentsRepository();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  AssignmentModel? _assignment;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final assignment =
          await _repository.fetchAssignmentById(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _assignment = assignment;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load assignment details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAssignment() async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.submitAssignment(
          widget.assignmentId, 'Submitted via app');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit assignment.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadAssignment,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _assignment!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(a.subject, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(a.dueDateLabel),
          const SizedBox(height: 4),
          Text('Status: ${a.statusLabel}'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(a.description),
                ],
              ),
            ),
          ),
          if (a.score != null && a.maxScore != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.grade_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'Score: ${a.score!.toStringAsFixed(0)}/${a.maxScore!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (a.feedback != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feedback',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(a.feedback!),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (a.status == AssignmentStatus.pending ||
              a.status == AssignmentStatus.overdue)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAssignment,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Assignment'),
              ),
            ),
        ],
      ),
    );
  }
}
