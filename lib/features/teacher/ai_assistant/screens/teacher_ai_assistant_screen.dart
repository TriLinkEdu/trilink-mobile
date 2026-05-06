import 'dart:async';

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
  bool _loadingRecommendations = false;
  bool _sendingAsk = false;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedSubjectId;
  String _selectedClassName = '';

  List<Map<String, dynamic>> _atRiskStudents = [];
  List<Map<String, dynamic>> _classPerformance = [];

  // studentId -> list of recommendation items
  final Map<String, List<Map<String, dynamic>>> _recommendations = {};

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
    final classPart = [
      gradeName,
      sectionName,
    ].where((s) => s.isNotEmpty).join(' ');
    if (classPart.isNotEmpty && subjectName.isNotEmpty)
      return '$classPart | $subjectName';
    if (classPart.isNotEmpty) return classPart;
    return subjectName.isNotEmpty ? subjectName : 'Unnamed Class';
  }

  Future<void> _loadAtRisk() async {
    if (_selectedSubjectId == null) return;
    setState(() => _loadingAtRisk = true);
    try {
      final data = await ApiService().getAiAtRiskStudents(_selectedSubjectId!);
      if (!mounted) return;
      setState(() {
        _atRiskStudents = data.cast<Map<String, dynamic>>();
        _loadingAtRisk = false;
      });
      // Fire-and-forget: fetch recommendations for at-risk students
      unawaited(_loadRecommendations());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAtRisk = false);
    }
  }

  Future<void> _loadRecommendations() async {
    if (_atRiskStudents.isEmpty || _selectedSubjectId == null) {
      setState(() {
        _recommendations.clear();
      });
      return;
    }
    setState(() {
      _loadingRecommendations = true;
      _recommendations.clear();
    });
    try {
      // Batch call recommendations for top 5 at-risk students
      final targets = _atRiskStudents.take(5).toList();
      final futures = targets.map((s) {
        final id = (s['studentId'] ?? s['id'] ?? s['userId']) as String?;
        if (id == null) return Future.value(<String, dynamic>{});
        return ApiService()
            .getAiRecommendations(id, subjectId: _selectedSubjectId, limit: 3)
            .then((r) => {'studentId': id, 'data': r});
      });
      final results = await Future.wait(futures);
      if (!mounted) return;
      for (final r in results) {
        final sid = r['studentId'] as String?;
        if (sid == null) continue;
        final data = r['data'] as Map<String, dynamic>?;
        if (data == null) continue;
        final items = (data['items'] ??
                data['recommendations'] ??
                data['resources'] ??
                []) as List<dynamic>;
        _recommendations[sid] =
            items.cast<Map<String, dynamic>>().toList();
      }
      setState(() {
        _loadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _loadClassPerformance() async {
    if (_selectedSubjectId == null) return;
    setState(() => _loadingPerformance = true);
    try {
      final data = await ApiService().getAiClassPerformance(
        _selectedSubjectId!,
      );
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
      final draft =
          result['draft'] as String? ??
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
                        const SizedBox(height: 16),
                        _buildClassHealthCard(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle('At-Risk Students'),
                        const SizedBox(height: 12),
                        _buildAtRiskSection(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Struggling Topics'),
                        const SizedBox(height: 12),
                        _buildClassPerformanceSection(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle('AI Recommendations'),
                        const SizedBox(height: 12),
                        _buildRecommendationsSection(theme),
                        if (_aiDraft != null) ...[
                          const SizedBox(height: 24),
                          _buildAiResponseCard(theme),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: _buildAskBar(),
                  ),
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
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
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
        ),
      );
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
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 24,
            ),
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
    final reason =
        student['reason'] as String? ??
        student['insight'] as String? ??
        'Low mastery or attendance detected';
    final isHigh =
        riskScore >= 0.7 ||
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      );
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
        final topicName =
            topic['topicName'] as String? ??
            topic['name'] as String? ??
            'Unknown Topic';
        final mastery =
            (topic['averageMastery'] as num? ?? topic['mastery'] as num? ?? 0)
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
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 18,
              ),
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

  Widget _buildClassHealthCard(ThemeData theme) {
    final atRiskCount = _atRiskStudents.length;
    double avgMastery = 0;
    if (_classPerformance.isNotEmpty) {
      double sum = 0;
      int count = 0;
      for (final t in _classPerformance) {
        final v = (t['averageMastery'] ?? t['mastery']) as num?;
        if (v != null) {
          sum += v.toDouble();
          count++;
        }
      }
      avgMastery = count > 0 ? (sum / count) * 100 : 0;
    }
    String topWeak = '—';
    if (_classPerformance.isNotEmpty) {
      final sorted = [..._classPerformance]..sort((a, b) {
          final va = (a['averageMastery'] ?? a['mastery'] ?? 1) as num;
          final vb = (b['averageMastery'] ?? b['mastery'] ?? 1) as num;
          return va.compareTo(vb);
        });
      topWeak = (sorted.first['topicName'] ??
              sorted.first['name'] ??
              '—')
          .toString();
    }

    final healthColor = avgMastery >= 70
        ? AppColors.success
        : avgMastery >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  color: healthColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'CLASS HEALTH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  theme,
                  label: 'At Risk',
                  value: '$atRiskCount',
                  color: atRiskCount > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHealthMetric(
                  theme,
                  label: 'Avg Mastery',
                  value: '${avgMastery.toStringAsFixed(0)}%',
                  color: healthColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHealthMetric(
                  theme,
                  label: 'Top Weak Topic',
                  value: topWeak.length > 10
                      ? '${topWeak.substring(0, 10)}…'
                      : topWeak,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(ThemeData theme,
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    if (_loadingRecommendations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_atRiskStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No students need recommendations right now.',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_recommendations.values.every((v) => v.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'AI is preparing recommendations. Check back shortly.',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _atRiskStudents.take(5).map((student) {
        final id = (student['studentId'] ?? student['id'] ?? student['userId'])
            as String?;
        final items = id != null ? (_recommendations[id] ?? []) : <Map<String, dynamic>>[];
        final name =
            '${student['firstName'] ?? student['name'] ?? 'Student'} ${student['lastName'] ?? ''}'
                .trim();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                name
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .map((w) => w[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              items.isEmpty
                  ? 'No recommendations'
                  : '${items.length} recommended ${items.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: items.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No specific recommendations from AI yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]
                : items.map((it) => _buildRecommendationItem(theme, it)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationItem(ThemeData theme, Map<String, dynamic> item) {
    final type = (item['type'] ?? 'resource') as String;
    final title = (item['title'] ?? 'Untitled') as String;
    final reason = (item['reason'] ?? item['source'] ?? '') as String;
    final difficulty = item['difficulty'] as String?;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _iconForType(type),
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (difficulty != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      difficulty.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'reading':
      case 'article':
        return Icons.menu_book_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'practice':
        return Icons.fitness_center;
      case 'topic':
        return Icons.topic_outlined;
      default:
        return Icons.lightbulb_outline;
    }
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
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
