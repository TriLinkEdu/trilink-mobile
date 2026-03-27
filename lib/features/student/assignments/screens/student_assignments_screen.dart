import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../models/assignment_model.dart';
import '../repositories/mock_student_assignments_repository.dart';
import '../repositories/student_assignments_repository.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final StudentAssignmentsRepository? repository;

  const StudentAssignmentsScreen({super.key, this.repository});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  late final StudentAssignmentsRepository _repository =
      widget.repository ?? MockStudentAssignmentsRepository();
  bool _isLoading = true;
  String? _error;
  List<AssignmentModel> _assignments = const [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final assignments = await _repository.fetchAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load assignments.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Colors.orange;
      case AssignmentStatus.submitted:
        return Colors.blue;
      case AssignmentStatus.graded:
        return Colors.green;
      case AssignmentStatus.overdue:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
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
                        onPressed: _loadAssignments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _assignments.isEmpty
                  ? const Center(child: Text('No assignments available.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _assignments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final assignment = _assignments[index];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            title: Text(
                              assignment.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${assignment.subject} • ${assignment.dueDateLabel}',
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(assignment.status)
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                assignment.statusLabel,
                                style: TextStyle(
                                  color: _statusColor(assignment.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                RouteNames.studentAssignmentDetail,
                                arguments: {
                                  'assignmentId': assignment.id,
                                },
                              );
                              if (result == true) {
                                _loadAssignments();
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
