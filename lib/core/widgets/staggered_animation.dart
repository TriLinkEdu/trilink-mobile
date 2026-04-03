import 'dart:math';
import 'package:flutter/material.dart';

/// Fades + slides a single child in with a configurable delay.
/// Caps the maximum stagger delay to avoid long invisible items
/// in long lists. Skips animation on subsequent mounts when
/// used inside recycling lists (starts fully visible).
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final double slideOffset;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.slideOffset = 20,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  static const _maxStaggerMs = 600;

  /// Tracks which parent widget trees have already animated their children.
  /// Uses the parent Element's hashCode as a rough session key so that
  /// scrolling back doesn't replay animations for items already seen.
  static final _animatedParents = <int, Set<int>>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final parentHash = context.hashCode;
    final seen = _animatedParents.putIfAbsent(parentHash, () => <int>{});
    final itemKey = widget.index;

    if (seen.contains(itemKey)) {
      _controller.value = 1.0;
    } else {
      seen.add(itemKey);
      final delayMs = min(
        widget.staggerDelay.inMilliseconds * widget.index,
        _maxStaggerMs,
      );
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: _offset.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// A Column that applies StaggeredFadeSlide to each child.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          StaggeredFadeSlide(
            index: i,
            child: children[i],
          ),
      ],
    );
  }
}
