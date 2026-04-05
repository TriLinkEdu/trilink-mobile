import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../shared/widgets/role_page_background.dart';

class ReportComparisonScreen extends StatefulWidget {
  final String? studentId;

  const ReportComparisonScreen({super.key, this.studentId});

  @override
  State<ReportComparisonScreen> createState() => _ReportComparisonScreenState();
}

class _ReportComparisonScreenState extends State<ReportComparisonScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _comparison = {};
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      _studentId = widget.studentId ?? '';
      if (_studentId.isEmpty) {
        final dashboard = await ApiService().getParentDashboard();
        final linked = (dashboard['linkedChildren'] as List<dynamic>?) ?? [];
        if (linked.isNotEmpty) {
          _studentId =
              linked[0]['studentId'] as String? ??
              linked[0]['id'] as String? ??
              '';
        }
      }

      if (_studentId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

      final data = await ApiService().getStudentCompare(_studentId);
      if (!mounted) return;
      setState(() {
        _comparison = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Reports')),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _comparison.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 56,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No comparison data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallComparison(),
                      const SizedBox(height: 16),
                      _buildSubjectComparison(),
                      const SizedBox(height: 16),
                      _buildTrendSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOverallComparison() {
    final theme = Theme.of(context);
    final current = _comparison['currentPeriod'] as Map<String, dynamic>?;
    final previous = _comparison['previousPeriod'] as Map<String, dynamic>?;
    if (current == null && previous == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Comparison',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ComparisonBlock(
                    label: current?['label'] as String? ?? 'Current',
                    value: current?['average']?.toString() ?? '--',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ComparisonBlock(
                    label: previous?['label'] as String? ?? 'Previous',
                    value: previous?['average']?.toString() ?? '--',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_comparison['change'] != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Change: ${_comparison['change']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectComparison() {
    final theme = Theme.of(context);
    final subjects = (_comparison['subjects'] as List<dynamic>?) ?? [];
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By Subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...subjects.map<Widget>((s) {
              final subj = s as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        subj['name'] as String? ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subj['current']?.toString() ?? '--',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subj['previous']?.toString() ?? '--',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subj['change']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              (subj['change']?.toString() ?? '').startsWith('-')
                              ? AppColors.error
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection() {
    final theme = Theme.of(context);
    final notes = _comparison['notes'] as String?;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              notes,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ComparisonBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.contains('%') ? value : '$value%',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
