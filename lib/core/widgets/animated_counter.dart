import 'package:flutter/material.dart';
import 'package:trilink_mobile/core/theme/app_colors.dart';

class AnimatedCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;
  final bool showTrend;
  final double? previousValue;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix = '%',
    this.duration = const Duration(milliseconds: 800),
    this.showTrend = false,
    this.previousValue,
    this.decimalPlaces = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _beginValue;

  @override
  void initState() {
    super.initState();
    _beginValue = widget.previousValue ?? widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: _beginValue, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _beginValue = old.value;
      _animation = Tween<double>(begin: _beginValue, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final diff = widget.value - _beginValue;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_animation.value.toStringAsFixed(widget.decimalPlaces)}${widget.suffix}',
              style: widget.style,
            ),
            if (widget.showTrend && diff.abs() > 0.5) ...[
              const SizedBox(width: 4),
              _TrendArrow(
                isUp: diff > 0,
                theme: theme,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TrendArrow extends StatelessWidget {
  final bool isUp;
  final ThemeData theme;

  const _TrendArrow({required this.isUp, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = isUp ? AppColors.success : theme.colorScheme.error;
    return Icon(
      isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      size: 18,
      color: color,
    );
  }
}
