import 'package:flutter/material.dart';
import '../theme/app_durations.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// Animated shimmer placeholder for skeleton loading states.
class ShimmerLoading extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).ext;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.borderSm,
            gradient: LinearGradient(
              colors: [
                ext.shimmerBase,
                ext.shimmerHighlight,
                ext.shimmerBase,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(2, 0.3),
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer card placeholder.
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerLoading(
        height: height,
        borderRadius: AppRadius.borderLg,
      ),
    );
  }
}

/// Vertical list of shimmer items.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => ShimmerCard(height: itemHeight),
      ),
    );
  }
}
