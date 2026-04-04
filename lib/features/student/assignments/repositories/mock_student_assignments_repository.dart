import '../models/assignment_model.dart';
import 'student_assignments_repository.dart';

class MockStudentAssignmentsRepository implements StudentAssignmentsRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<AssignmentModel> _assignments = [
    AssignmentModel(
      id: 'a1',
      title: 'Linear Algebra Problem Set',
      subject: 'Mathematics',
      description: 'Solve exercises 3.1 through 3.15 on matrix multiplication and determinants.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: AssignmentStatus.pending,
    ),
    AssignmentModel(
      id: 'a2',
      title: 'Newton\'s Laws Lab Report',
      subject: 'Physics',
      description: 'Write a lab report on the Newton\'s second law experiment performed in class.',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      status: AssignmentStatus.overdue,
    ),
    AssignmentModel(
      id: 'a3',
      title: 'Essay: Themes in Hamlet',
      subject: 'Literature',
      description: 'Analyze the major themes present in Shakespeare\'s Hamlet. 1500-2000 words.',
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: AssignmentStatus.graded,
      score: 88,
      maxScore: 100,
      feedback: 'Excellent analysis of the theme of indecision. Could improve on textual evidence.',
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
      submittedContent: 'In Shakespeare\'s Hamlet, the recurring theme of indecision drives the narrative forward. Prince Hamlet\'s inability to act decisively upon learning of his father\'s murder creates a cascade of consequences that ultimately lead to tragedy...',
    ),
    AssignmentModel(
      id: 'a4',
      title: 'Derivative Worksheet',
      subject: 'Mathematics',
      description: 'Complete the worksheet on differentiation rules and chain rule applications.',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      status: AssignmentStatus.pending,
    ),
    AssignmentModel(
      id: 'a5',
      title: 'Circuit Analysis Report',
      subject: 'Physics',
      description: 'Analyze the series and parallel circuits from the lab and calculate total resistance.',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      status: AssignmentStatus.submitted,
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      submittedContent: 'For the series circuit with R1=100Ω, R2=220Ω, R3=330Ω, the total resistance is R_total = R1 + R2 + R3 = 650Ω. For the parallel circuit, 1/R_total = 1/R1 + 1/R2 + 1/R3, giving R_total ≈ 56.9Ω.',
    ),
    AssignmentModel(
      id: 'a6',
      title: 'Poetry Comparison Essay',
      subject: 'Literature',
      description: 'Compare and contrast two poems from the Romantic period. 1000-1500 words.',
      dueDate: DateTime.now().subtract(const Duration(days: 10)),
      status: AssignmentStatus.graded,
      score: 92,
      maxScore: 100,
      feedback: 'Outstanding comparative analysis with strong use of literary devices.',
      submittedAt: DateTime.now().subtract(const Duration(days: 12)),
      submittedContent: 'The Romantic period produced poets whose works reflected deep emotional connections with nature and the human condition. Comparing Wordsworth\'s "I Wandered Lonely as a Cloud" with Keats\'s "Ode to a Nightingale" reveals both shared ideals and distinct approaches...',
    ),
  ];

  @override
  Future<List<AssignmentModel>> fetchAssignments() async {
    await Future<void>.delayed(_latency);
    return List<AssignmentModel>.from(_assignments);
  }

  @override
  Future<AssignmentModel> fetchAssignmentById(String id) async {
    await Future<void>.delayed(_latency);
    return _assignments.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> submitAssignment(String id, String content) async {
    await Future<void>.delayed(_latency);
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assignments[index] = _assignments[index].copyWith(
        status: AssignmentStatus.submitted,
        submittedAt: DateTime.now(),
        submittedContent: content,
      );
    }
  }
}
