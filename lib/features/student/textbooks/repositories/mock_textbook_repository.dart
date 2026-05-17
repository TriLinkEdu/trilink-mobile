import '../models/textbook_model.dart';
import 'textbook_repository.dart';

class MockTextbookRepository implements TextbookRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<TextbookModel> _textbooks = [
    TextbookModel(
      id: 'tb1',
      title: 'Grade 9 Mathematics — New Curriculum (Ethiopian)',
      subject: 'Mathematics',
      grade: 9,
      description:
          'Official Ethiopian Grade 9 mathematics student textbook covering algebra, geometry, trigonometry, statistics and probability.',
      pageCount: 350,
      sizeBytes: 19070511,
      isActive: true,
      fileRecordId: 'file-tb1',
      fileVersion: '1',
      fileEtag: null,
      cacheKey: 'file-tb1:1',
      accessUrl: 'https://example.com/textbooks/mathematics-grade9.pdf',
      coverUrl: 'https://example.com/textbooks/mathematics-grade9-cover.png',
      createdAt: DateTime(2025, 9, 1),
    ),
    TextbookModel(
      id: 'tb2',
      title: 'Grade 9 Physics — New Curriculum (Ethiopian)',
      subject: 'Physics',
      grade: 9,
      description:
          'Official Ethiopian Grade 9 physics student textbook covering motion, forces, energy, waves and thermodynamics.',
      pageCount: 280,
      sizeBytes: 8169671,
      isActive: true,
      fileRecordId: 'file-tb2',
      fileVersion: '1',
      fileEtag: null,
      cacheKey: 'file-tb2:1',
      accessUrl: 'https://example.com/textbooks/physics-grade9.pdf',
      coverUrl: 'https://example.com/textbooks/physics-grade9-cover.png',
      createdAt: DateTime(2025, 9, 1),
    ),
    TextbookModel(
      id: 'tb3',
      title: 'Grade 9 Chemistry — New Curriculum (Ethiopian)',
      subject: 'Chemistry',
      grade: 9,
      description:
          'Official Ethiopian Grade 9 chemistry student textbook covering atomic theory, the periodic table and chemical reactions.',
      pageCount: 240,
      sizeBytes: 7611573,
      isActive: true,
      fileRecordId: 'file-tb3',
      fileVersion: '1',
      fileEtag: null,
      cacheKey: 'file-tb3:1',
      accessUrl: 'https://example.com/textbooks/chemistry-grade9.pdf',
      coverUrl: 'https://example.com/textbooks/chemistry-grade9-cover.png',
      createdAt: DateTime(2025, 9, 1),
    ),
    TextbookModel(
      id: 'tb4',
      title: 'Grade 9 Biology — New Curriculum (Ethiopian)',
      subject: 'Biology',
      grade: 9,
      description:
          'Official Ethiopian Grade 9 biology student textbook covering cell biology, genetics, classification and ecology.',
      pageCount: 320,
      sizeBytes: 11533633,
      isActive: true,
      fileRecordId: 'file-tb4',
      fileVersion: '1',
      fileEtag: null,
      cacheKey: 'file-tb4:1',
      accessUrl: 'https://example.com/textbooks/biology-grade9.pdf',
      coverUrl: 'https://example.com/textbooks/biology-grade9-cover.png',
      createdAt: DateTime(2025, 9, 1),
    ),
    TextbookModel(
      id: 'tb5',
      title: 'Grade 9 History — New Curriculum (Ethiopian)',
      subject: 'History',
      grade: 9,
      description:
          'Official Ethiopian Grade 9 history student textbook covering ancient civilizations, African kingdoms and modern revolutions.',
      pageCount: 290,
      sizeBytes: 9403416,
      isActive: true,
      fileRecordId: 'file-tb5',
      fileVersion: '1',
      fileEtag: null,
      cacheKey: 'file-tb5:1',
      accessUrl: 'https://example.com/textbooks/history-grade9.pdf',
      coverUrl: 'https://example.com/textbooks/history-grade9-cover.png',
      createdAt: DateTime(2025, 9, 1),
    ),
  ];

  @override
  Future<List<TextbookModel>> fetchTextbooks({
    String? subject,
    int? grade,
  }) async {
    await Future<void>.delayed(_latency);
    var results = _textbooks;
    if (subject != null) {
      results = results
          .where((t) => t.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    }
    if (grade != null) {
      results = results.where((t) => t.grade == grade).toList();
    }
    return results;
  }

  @override
  Future<TextbookModel?> fetchTextbookById(String id) async {
    await Future<void>.delayed(_latency);
    for (final textbook in _textbooks) {
      if (textbook.id == id) return textbook;
    }
    return null;
  }

  @override
  List<TextbookModel>? getCached() => null;

  @override
  void clearCache() {}
}
