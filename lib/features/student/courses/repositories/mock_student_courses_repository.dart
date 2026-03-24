import '../models/course_resource_model.dart';
import 'student_courses_repository.dart';

class MockStudentCoursesRepository implements StudentCoursesRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<CourseResourceModel> _resources = [
    CourseResourceModel(
      id: 'cr1',
      title: 'Calculus Fundamentals',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      type: ResourceType.pdf,
      description: 'Introduction to limits, derivatives, and integrals.',
      url: 'https://example.com/resources/calculus-fundamentals.pdf',
      fileSize: '2.4 MB',
      uploadedAt: DateTime(2025, 9, 5),
    ),
    CourseResourceModel(
      id: 'cr2',
      title: 'Linear Algebra Lecture Recording',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      type: ResourceType.video,
      description: 'Recorded lecture on eigenvalues and eigenvectors.',
      url: 'https://example.com/videos/linear-algebra-lec12.mp4',
      fileSize: '340 MB',
      uploadedAt: DateTime(2025, 10, 1),
    ),
    CourseResourceModel(
      id: 'cr3',
      title: 'Mechanics Problem Set Solutions',
      subjectId: 'physics',
      subjectName: 'Physics',
      type: ResourceType.pdf,
      description: 'Worked solutions for chapters 4-6 on classical mechanics.',
      url: 'https://example.com/resources/mechanics-solutions.pdf',
      fileSize: '1.8 MB',
      uploadedAt: DateTime(2025, 9, 20),
    ),
    CourseResourceModel(
      id: 'cr4',
      title: 'Electromagnetic Waves Simulation',
      subjectId: 'physics',
      subjectName: 'Physics',
      type: ResourceType.link,
      description: 'Interactive PhET simulation for electromagnetic wave properties.',
      url: 'https://phet.colorado.edu/en/simulation/wave-on-a-string',
      uploadedAt: DateTime(2025, 10, 8),
    ),
    CourseResourceModel(
      id: 'cr5',
      title: 'Shakespeare Study Guide',
      subjectId: 'literature',
      subjectName: 'Literature',
      type: ResourceType.document,
      description: 'Comprehensive study guide covering major works and themes.',
      url: 'https://example.com/resources/shakespeare-guide.docx',
      fileSize: '890 KB',
      uploadedAt: DateTime(2025, 9, 12),
    ),
    CourseResourceModel(
      id: 'cr6',
      title: 'Romantic Poetry Analysis',
      subjectId: 'literature',
      subjectName: 'Literature',
      type: ResourceType.video,
      description: 'Video essay on key characteristics of Romantic-era poetry.',
      url: 'https://example.com/videos/romantic-poetry.mp4',
      fileSize: '210 MB',
      uploadedAt: DateTime(2025, 10, 3),
    ),
    CourseResourceModel(
      id: 'cr7',
      title: 'Thermodynamics Reference Sheet',
      subjectId: 'physics',
      subjectName: 'Physics',
      type: ResourceType.pdf,
      description: 'Formula sheet for thermodynamics laws and equations.',
      url: 'https://example.com/resources/thermo-reference.pdf',
      fileSize: '450 KB',
      uploadedAt: DateTime(2025, 10, 10),
    ),
    CourseResourceModel(
      id: 'cr8',
      title: 'Khan Academy: Integration Techniques',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      type: ResourceType.link,
      description: 'External resource covering integration by parts and substitution.',
      url: 'https://www.khanacademy.org/math/ap-calculus-bc/bc-integration-new',
      uploadedAt: DateTime(2025, 9, 28),
    ),
  ];

  @override
  Future<List<CourseResourceModel>> fetchCourseResources() async {
    await Future<void>.delayed(_latency);
    return List<CourseResourceModel>.from(_resources);
  }

  @override
  Future<List<CourseResourceModel>> fetchResourcesBySubject(
    String subjectId,
  ) async {
    await Future<void>.delayed(_latency);
    return _resources.where((r) => r.subjectId == subjectId).toList();
  }
}
