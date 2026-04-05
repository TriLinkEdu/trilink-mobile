import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _latexController = TextEditingController(
    text: r'\int_{a}^{b} x^2 dx',
  );
  final int _currentQuestion = 1;
  bool _submitting = false;

  final List<String> _mathSymbols = ['∫', 'Σ', '√', 'x/y', 'π', 'θ', '∞'];

  @override
  void dispose() {
    _titleController.dispose();
    _latexController.dispose();
    super.dispose();
  }

  void _insertSymbol(String symbol) {
    final text = _latexController.text;
    final selection = _latexController.selection;
    final newText = text.replaceRange(selection.start, selection.end, symbol);
    _latexController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + symbol.length,
      ),
    );
    setState(() {});
  }

  Future<void> _saveExam({required bool publish}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exam title')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = <String, dynamic>{
        'title': title,
        'status': publish ? 'published' : 'draft',
      };

      if (_latexController.text.trim().isNotEmpty) {
        data['questions'] = [
          {'text': _latexController.text.trim(), 'type': 'latex'},
        ];
      }

      final result = await ApiService().createExam(data);

      if (publish) {
        final examId = result['_id'] ?? result['id'];
        if (examId != null) {
          await ApiService().publishExam(examId.toString());
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(publish ? 'Exam published!' : 'Draft saved!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 15),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'Create New Exam',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExamTitleField(),
                  const SizedBox(height: 24),
                  _buildQuestionEditor(),
                  const SizedBox(height: 20),
                  _buildLatexPreview(),
                  const SizedBox(height: 28),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildExamTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exam Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Calculus Midterm II',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
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
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Question Editor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Question $_currentQuestion',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: _mathSymbols
                      .map(
                        (s) => Expanded(
                          child: InkWell(
                            onTap: () => _insertSymbol(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              TextField(
                controller: _latexController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter LaTeX expression...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'LATEX',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLatexPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REAL-TIME PREVIEW',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              _formatLatexPreview(_latexController.text),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  String _formatLatexPreview(String latex) {
    return latex
        .replaceAll(r'\int', '∫')
        .replaceAll(r'\sum', 'Σ')
        .replaceAll(r'\sqrt', '√')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'_{', '')
        .replaceAll(r'}^{', '')
        .replaceAll(r'^{', '^')
        .replaceAll(r'^2', '²')
        .replaceAll('}', '')
        .replaceAll('{', '');
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.quiz_outlined,
            label: 'Question Bank',
            color: AppColors.primary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.image_outlined,
            label: 'Upload Image',
            color: AppColors.primary,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () => _saveExam(publish: false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Draft',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : () => _saveExam(publish: true),
              icon: const Icon(Icons.send, size: 16),
              label: const Text(
                'Publish',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
