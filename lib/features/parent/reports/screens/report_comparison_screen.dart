import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ReportComparisonScreen extends StatefulWidget {
  const ReportComparisonScreen({super.key});

  @override
  State<ReportComparisonScreen> createState() => _ReportComparisonScreenState();
}

class _ReportComparisonScreenState extends State<ReportComparisonScreen> {
  bool _compareChildren = true;

  int _childA = 0;
  int _childB = 1;

  int _selectedChild = 0;
  int _periodA = 0;
  int _periodB = 1;

  final List<String> _children = ['Ahmed Al-Rashid', 'Sara Al-Rashid', 'Omar Al-Rashid'];
  final List<String> _periods = ['Term 1', 'Term 2', 'Term 3'];

  final List<List<Map<String, dynamic>>> _childData = [
    [
      {'label': 'GPA', 'value': 3.7},
      {'label': 'Attendance', 'value': 94.0},
      {'label': 'Assignments', 'value': 88.0},
      {'label': 'Behavior', 'value': 4.2},
    ],
    [
      {'label': 'GPA', 'value': 3.9},
      {'label': 'Attendance', 'value': 97.0},
      {'label': 'Assignments', 'value': 92.0},
      {'label': 'Behavior', 'value': 4.5},
    ],
    [
      {'label': 'GPA', 'value': 3.4},
      {'label': 'Attendance', 'value': 90.0},
      {'label': 'Assignments', 'value': 80.0},
      {'label': 'Behavior', 'value': 3.8},
    ],
  ];

  final List<List<Map<String, dynamic>>> _periodData = [
    [
      {'label': 'GPA', 'value': 3.5},
      {'label': 'Attendance', 'value': 91.0},
      {'label': 'Assignments', 'value': 82.0},
      {'label': 'Behavior', 'value': 4.0},
    ],
    [
      {'label': 'GPA', 'value': 3.7},
      {'label': 'Attendance', 'value': 94.0},
      {'label': 'Assignments', 'value': 88.0},
      {'label': 'Behavior', 'value': 4.2},
    ],
    [
      {'label': 'GPA', 'value': 3.9},
      {'label': 'Attendance', 'value': 96.0},
      {'label': 'Assignments', 'value': 93.0},
      {'label': 'Behavior', 'value': 4.5},
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Reports',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildToggle(),
            const SizedBox(height: 20),
            if (_compareChildren) _buildChildrenMode() else _buildPeriodsMode(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _compareChildren = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _compareChildren ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _compareChildren
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                        : null,
                  ),
                  child: Text(
                    'Compare Children',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _compareChildren ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _compareChildren = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_compareChildren ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: !_compareChildren
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                        : null,
                  ),
                  child: Text(
                    'Compare Periods',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_compareChildren ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenMode() {
    final dataA = _childData[_childA];
    final dataB = _childData[_childB];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown(_children, _childA, (v) => setState(() => _childA = v), AppColors.primary)),
              const SizedBox(width: 12),
              const Text('vs', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown(_children, _childB, (v) => setState(() => _childB = v), AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.primary, _children[_childA]),
              const Spacer(),
              _legendDot(AppColors.secondary, _children[_childB]),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(dataA.length, (i) {
            return _buildComparisonCard(
              label: dataA[i]['label'] as String,
              valueA: dataA[i]['value'] as double,
              valueB: dataB[i]['value'] as double,
              maxValue: _maxForLabel(dataA[i]['label'] as String),
              unitA: _formatValue(dataA[i]['label'] as String, dataA[i]['value'] as double),
              unitB: _formatValue(dataB[i]['label'] as String, dataB[i]['value'] as double),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeriodsMode() {
    final dataA = _periodData[_periodA];
    final dataB = _periodData[_periodB];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDropdown(_children, _selectedChild, (v) => setState(() => _selectedChild = v), AppColors.primary),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown(_periods, _periodA, (v) => setState(() => _periodA = v), AppColors.primary)),
              const SizedBox(width: 12),
              const Text('vs', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown(_periods, _periodB, (v) => setState(() => _periodB = v), AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.primary, _periods[_periodA]),
              const Spacer(),
              _legendDot(AppColors.secondary, _periods[_periodB]),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(dataA.length, (i) {
            return _buildComparisonCard(
              label: dataA[i]['label'] as String,
              valueA: dataA[i]['value'] as double,
              valueB: dataB[i]['value'] as double,
              maxValue: _maxForLabel(dataA[i]['label'] as String),
              unitA: _formatValue(dataA[i]['label'] as String, dataA[i]['value'] as double),
              unitB: _formatValue(dataB[i]['label'] as String, dataB[i]['value'] as double),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> items, int selected, ValueChanged<int> onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: color, size: 20),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          items: List.generate(items.length, (i) {
            return DropdownMenuItem(value: i, child: Text(items[i]));
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  double _maxForLabel(String label) {
    switch (label) {
      case 'GPA':
        return 4.0;
      case 'Behavior':
        return 5.0;
      default:
        return 100.0;
    }
  }

  String _formatValue(String label, double value) {
    switch (label) {
      case 'GPA':
        return value.toStringAsFixed(1);
      case 'Behavior':
        return '${value.toStringAsFixed(1)}/5';
      default:
        return '${value.toStringAsFixed(0)}%';
    }
  }

  Widget _buildComparisonCard({
    required String label,
    required double valueA,
    required double valueB,
    required double maxValue,
    required String unitA,
    required String unitB,
  }) {
    final ratioA = (valueA / maxValue).clamp(0.0, 1.0);
    final ratioB = (valueB / maxValue).clamp(0.0, 1.0);
    final diff = valueA - valueB;

    Color indicatorColor;
    String indicatorText;
    if (diff.abs() < 0.01) {
      indicatorColor = AppColors.textSecondary;
      indicatorText = 'Equal';
    } else if (diff > 0) {
      indicatorColor = AppColors.primary;
      indicatorText = _compareChildren ? _children[_childA].split(' ').first : _periods[_periodA];
    } else {
      indicatorColor = AppColors.secondary;
      indicatorText = _compareChildren ? _children[_childB].split(' ').first : _periods[_periodB];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    indicatorText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: indicatorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(unitA, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const Spacer(),
                Text(unitB, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: ratioA,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: ratioB,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
