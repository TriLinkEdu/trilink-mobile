import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../shared/widgets/role_page_background.dart';
import '../../../auth/services/auth_service.dart';

class TeacherAiAssistantScreen extends StatefulWidget {
  const TeacherAiAssistantScreen({super.key});

  @override
  State<TeacherAiAssistantScreen> createState() =>
      _TeacherAiAssistantScreenState();
}

class _TeacherAiAssistantScreenState extends State<TeacherAiAssistantScreen> {
  final TextEditingController _askController = TextEditingController();

  bool _loadingClasses = true;
  bool _loadingAtRisk = false;
  bool _loadingPerformance = false;
  bool _sendingAsk = false;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedSubjectId;
  String _selectedClassName = '';

  List<Map<String, dynamic>> _atRiskStudents = [];
  List<Map<String, dynamic>> _classPerformance = [];

  String? _aiDraft;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _askController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
    });
    try {
      final yearData = await ApiService().getActiveAcademicYear();
      final yearId =
          (yearData['id'] ?? yearData['data']?['id']) as String? ?? '';
      if (yearId.isEmpty) throw Exception('No active academic year');

      final offerings = await ApiService().getMyClassOfferings(yearId);
      if (!mounted) return;

      final classes = offerings.cast<Map<String, dynamic>>();
      setState(() {
        _classOfferings = classes;
        _loadingClasses = false;
      });

      if (classes.isNotEmpty) {
        // Use subjectId for AI endpoints
        final first = classes.first;
        final subjectId = _extractSubjectId(first);
        if (subjectId != null) {
          _selectedSubjectId = subjectId;
          _selectedClassName = _labelFor(first);
          await Future.wait([_loadAtRisk(), _loadClassPerformance()]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
      });
    }
  }

  String? _extractSubjectId(Map<String, dynamic> offering) {
    // Backend returns subjectId directly or nested
    return offering['subjectId'] as String? ??
        (offering['subject'] as Map<String, dynamic>?)?['id'] as String?;
  }

  String _labelFor(Map<String, dynamic> offering) {
    final displayName = offering['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final gradeName = offering['gradeName'] as String? ?? '';
    final sectionName = offering['sectionName'] as String? ?? '';
    final subjectName = offering['subjectName'] as String? ?? '';
    final classPart =
        [gradeName, sectionName].where((s) => s.isNotEmpty).join(' ');
    if (classPart.isNotEmpty && subjectName.isNotEmpty)
      return '$classPart | $subjectName';
    if (classPart.isNotEmpty) return classPart;
    return subjectName.isNotEmpty ? subjectName : 'Unnamed Class';
  }

  Future<void> _loadAtRisk() async {
    if (_selectedSubjectId == null) return;
    setState(() => _loadingAtRisk = true);
    try {
      final data =
          await ApiService().getAiAtRiskStudents(_selectedSubjectId!);
      if (!mounted) return;
      setState(() {
        _atRiskStudents = data.cast<Map<String, dynamic>>();
        _loadingAtRisk = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAtRisk = false);
    }
  }

  Future<void> _loadClassPerformance() async {
    if (_selectedSubjectId == null) return;
    setState(() => _loadingPerformance = true);
    try {
      final data =
          await ApiService().getAiClassPerformance(_selectedSubjectId!);
      if (!mounted) return;
      setState(() {
        _classPerformance = data.cast<Map<String, dynamic>>();
        _loadingPerformance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPerformance = false);
    }
  }

  Future<void> _sendAsk() async {
    final text = _askController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sendingAsk = true;
      _aiDraft = null;
    });
    try {
      final result = await ApiService().postAiFeedbackAssistant(
        text,
        AuthService().currentUser?.role.name ?? 'teacher',
      );
      if (!mounted) return;
      final draft = result['draft'] as String? ??
          result['response'] as String? ??
          result['message'] as String? ??
          '';
      setState(() {
        _aiDraft = draft.isNotEmpty ? draft : 'No response from AI.';
        _sendingAsk = false;
      });
      _askController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiDraft = 'AI service unavailable. Please try again later.';
        _sendingAsk = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Teaching Assistant',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
        ],
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.teacher,
        child: _loadingClasses
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class selector
                        if (_classOfferings.isNotEmpty)
                          _buildClassSelector(theme),
                        const SizedBox(height: 20),
                        _buildClassInsightsCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('At-Risk Students'),
                        const SizedBox(height: 12),
                        _buildAtRiskSection(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Struggling Topics'),
                        const SizedBox(height: 12),
                        _buildClassPerformanceSection(theme),
                        if (_aiDraft != null) ...[
                          const SizedBox(height: 24),
                          _buildAiResponseCard(theme),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                      left: 16, right: 16, bottom: 24, child: _buildAskBar()),
                ],
              ),
      ),
    );
  }

  Widget _buildClassSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubjectId,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurfaceVariant),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          items: _classOfferings.map((c) {
            final subjectId = _extractSubjectId(c);
            return DropdownMenuItem(
              value: subjectId,
              child: Text(_labelFor(c)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedSubjectId) {
              final offering = _classOfferings.firstWhere(
                (c) => _extractSubjectId(c) == val,
                orElse: () => {},
              );
              setState(() {
                _selectedSubjectId = val;
                _selectedClassName = _labelFor(offering);
                _atRiskStudents = [];
                _classPerformance = [];
              });
              Future.wait([_loadAtRisk(), _loadClassPerformance()]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildClassInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedClassName.isNotEmpty
                      ? _selectedClassName
                      : 'Class Insights',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _atRiskStudents.isEmpty && !_loadingAtRisk
                        ? 'No at-risk students detected. Great work!'
                        : '${_atRiskStudents.length} student${_atRiskStudents.length == 1 ? '' : 's'} may need attention.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskSection(ThemeData theme) {
    if (_loadingAtRisk) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    if (_atRiskStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No at-risk students detected for this subject.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _atRiskStudents.map((s) => _buildAtRiskCard(s)).toList(),
    );
  }

  Widget _buildAtRiskCard(Map<String, dynamic> student) {
    final theme = Theme.of(context);
    final name =
        '${student['firstName'] ?? student['name'] ?? 'Unknown'} ${student['lastName'] ?? ''}'
            .trim();
    final riskScore = student['riskScore'] as num? ?? 0;
    final reason = student['reason'] as String? ??
        student['insight'] as String? ??
        'Low mastery or attendance detected';
    final isHigh = riskScore >= 0.7 ||
        (student['riskLevel'] as String? ?? '').toLowerCase() == 'high';
    final riskColor = isHigh ? AppColors.error : Colors.orange;
    final riskLabel = isHigh ? 'High Risk' : 'Medium Risk';

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: riskColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              riskLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: riskColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPerformanceSection(ThemeData theme) {
    if (_loadingPerformance) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    if (_classPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No topic performance data available yet.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _classPerformance.take(5).map((topic) {
        final topicName = topic['topicName'] as String? ??
            topic['name'] as String? ??
            'Unknown Topic';
        final mastery = (topic['averageMastery'] as num? ??
                topic['mastery'] as num? ??
                0)
            .toDouble();
        final pct = (mastery * 100).clamp(0.0, 100.0);
        final color = pct >= 70
            ? Colors.green
            : pct >= 50
                ? Colors.orange
                : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topicName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAiResponseCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Response',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _aiDraft!,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _askController,
              decoration: InputDecoration(
                hintText: 'Ask AI anything about your class...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _sendAsk(),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF6C63FF)],
              ),
              shape: BoxShape.circle,
            ),
            child: _sendingAsk
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendAsk,
                  ),
          ),
        ],
      ),
    );
  }
}
