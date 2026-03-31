import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExamBankScreen extends StatefulWidget {
  const ExamBankScreen({super.key});

  @override
  State<ExamBankScreen> createState() => _ExamBankScreenState();
}

class _ExamBankScreenState extends State<ExamBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'MCQ', 'Short Answer', 'Essay', 'LaTeX'];

  final List<_BankQuestion> _questions = [
    _BankQuestion(
      id: 1,
      text: 'What is the derivative of f(x) = 3x² + 2x - 5?',
      type: 'MCQ',
      subject: 'Calculus',
      points: 5,
      hasLatex: true,
      hasImage: false,
    ),
    _BankQuestion(
      id: 2,
      text: 'Explain Newton\'s Second Law of Motion and provide two real-world examples.',
      type: 'Essay',
      subject: 'Physics',
      points: 15,
      hasLatex: false,
      hasImage: false,
    ),
    _BankQuestion(
      id: 3,
      text: 'Solve the integral ∫(2x + 1)dx from 0 to 3.',
      type: 'Short Answer',
      subject: 'Calculus',
      points: 8,
      hasLatex: true,
      hasImage: false,
    ),
    _BankQuestion(
      id: 4,
      text: 'Which of the following is a property of electromagnetic waves?',
      type: 'MCQ',
      subject: 'Physics',
      points: 3,
      hasLatex: false,
      hasImage: true,
    ),
    _BankQuestion(
      id: 5,
      text: 'Find the eigenvalues of the matrix A = [[2, 1], [1, 2]].',
      type: 'Short Answer',
      subject: 'Linear Algebra',
      points: 10,
      hasLatex: true,
      hasImage: false,
    ),
    _BankQuestion(
      id: 6,
      text: 'Describe the process of cellular respiration and its stages.',
      type: 'Essay',
      subject: 'Biology',
      points: 20,
      hasLatex: false,
      hasImage: true,
    ),
    _BankQuestion(
      id: 7,
      text: 'What is the pH of a 0.01M HCl solution?',
      type: 'MCQ',
      subject: 'Chemistry',
      points: 4,
      hasLatex: false,
      hasImage: false,
    ),
    _BankQuestion(
      id: 8,
      text: 'Prove that the sum of angles in a triangle equals 180° using the parallel postulate.',
      type: 'Essay',
      subject: 'Geometry',
      points: 12,
      hasLatex: true,
      hasImage: true,
    ),
  ];

  String _newQuestionText = '';
  String _newQuestionType = 'MCQ';
  String _newQuestionSubject = 'Calculus';
  int _newQuestionPoints = 5;
  bool _newHasLatex = false;
  bool _newHasImage = false;

  List<_BankQuestion> get _filteredQuestions {
    var results = _questions;
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'LaTeX') {
        results = results.where((q) => q.hasLatex).toList();
      } else {
        results = results.where((q) => q.type == _selectedFilter).toList();
      }
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      results = results
          .where((q) =>
              q.text.toLowerCase().contains(query) ||
              q.subject.toLowerCase().contains(query))
          .toList();
    }
    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Question Bank',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // Focus the search field
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(child: _buildQuestionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search questions...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuestionList() {
    final questions = _filteredQuestions;
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No questions found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return _QuestionCard(
          question: questions[index],
          onEdit: () => _showEditQuestion(questions[index]),
          onDelete: () => _deleteQuestion(questions[index]),
        );
      },
    );
  }

  void _deleteQuestion(_BankQuestion question) {
    setState(() {
      _questions.removeWhere((q) => q.id == question.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Question #${question.id} deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: () {
          setState(() => _questions.add(question));
        }),
      ),
    );
  }

  void _showEditQuestion(_BankQuestion question) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing Question #${question.id}')),
    );
  }

  void _showAddQuestionSheet() {
    _newQuestionText = '';
    _newQuestionType = 'MCQ';
    _newQuestionSubject = 'Calculus';
    _newQuestionPoints = 5;
    _newHasLatex = false;
    _newHasImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Question',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 3,
                      onChanged: (v) => _newQuestionText = v,
                      decoration: InputDecoration(
                        hintText: 'Enter question text...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Type',
                            value: _newQuestionType,
                            items: ['MCQ', 'Short Answer', 'Essay'],
                            onChanged: (v) {
                              setSheetState(() => _newQuestionType = v!);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Subject',
                            value: _newQuestionSubject,
                            items: [
                              'Calculus',
                              'Physics',
                              'Linear Algebra',
                              'Biology',
                              'Chemistry',
                              'Geometry',
                            ],
                            onChanged: (v) {
                              setSheetState(() => _newQuestionSubject = v!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _newQuestionPoints = int.tryParse(v) ?? 5,
                      decoration: InputDecoration(
                        hintText: '5',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleOption(
                            icon: Icons.functions,
                            label: 'Add LaTeX',
                            isActive: _newHasLatex,
                            onTap: () {
                              setSheetState(
                                () => _newHasLatex = !_newHasLatex,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ToggleOption(
                            icon: Icons.image_outlined,
                            label: 'Add Image',
                            isActive: _newHasImage,
                            onTap: () {
                              setSheetState(
                                () => _newHasImage = !_newHasImage,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_newQuestionText.trim().isEmpty) return;
                          setState(() {
                            _questions.add(_BankQuestion(
                              id: _questions.length + 1,
                              text: _newQuestionText,
                              type: _newQuestionType,
                              subject: _newQuestionSubject,
                              points: _newQuestionPoints,
                              hasLatex: _newHasLatex,
                              hasImage: _newHasImage,
                            ));
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add Question',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankQuestion {
  final int id;
  final String text;
  final String type;
  final String subject;
  final int points;
  final bool hasLatex;
  final bool hasImage;

  _BankQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.subject,
    required this.points,
    required this.hasLatex,
    required this.hasImage,
  });
}

class _QuestionCard extends StatelessWidget {
  final _BankQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _typeBadgeColor {
    switch (question.type) {
      case 'MCQ':
        return AppColors.primary;
      case 'Short Answer':
        return AppColors.accent;
      case 'Essay':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${question.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _typeBadgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _typeBadgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.subject,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${question.points} pts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (question.hasLatex)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.functions,
                    size: 18,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              if (question.hasImage)
                Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.secondary.withValues(alpha: 0.7),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
