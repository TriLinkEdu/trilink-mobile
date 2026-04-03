import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CelebrationType { streak, grade, levelUp, achievement, completion }

class CelebrationOverlay extends StatefulWidget {
  final Widget child;

  const CelebrationOverlay({super.key, required this.child});

  static CelebrationOverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<CelebrationOverlayState>();
  }

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _bannerController;
  late final Animation<double> _bannerSlide;
  late final Animation<double> _bannerFade;
  Timer? _dismissTimer;

  String _bannerText = '';
  String _bannerSubtext = '';
  IconData _bannerIcon = Icons.celebration_rounded;
  List<Color> _bannerGradient = AppGradients.achievement.colors;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _bannerSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack),
    );
    _bannerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _confettiController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void celebrate({
    required CelebrationType type,
    required String message,
    String? subtext,
  }) {
    _dismissTimer?.cancel();

    final config = _typeConfig(type);
    setState(() {
      _bannerText = message;
      _bannerSubtext = subtext ?? '';
      _bannerIcon = config.icon;
      _bannerGradient = config.gradient;
    });

    _confettiController.play();
    _bannerController
      ..reset()
      ..forward();

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _bannerController.reverse();
    });
  }

  _CelebrationConfig _typeConfig(CelebrationType type) {
    switch (type) {
      case CelebrationType.streak:
        return _CelebrationConfig(
          Icons.local_fire_department_rounded,
          AppGradients.streak.colors,
        );
      case CelebrationType.grade:
        return _CelebrationConfig(
          Icons.school_rounded,
          AppGradients.primaryHero.colors,
        );
      case CelebrationType.levelUp:
        return _CelebrationConfig(
          Icons.arrow_upward_rounded,
          AppGradients.level.colors,
        );
      case CelebrationType.achievement:
        return _CelebrationConfig(
          Icons.emoji_events_rounded,
          AppGradients.achievement.colors,
        );
      case CelebrationType.completion:
        return _CelebrationConfig(
          Icons.check_circle_rounded,
          [AppColors.success, const Color(0xFF6EE7B7)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,

        Positioned(
          top: top + 20,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.2,
              colors: const [
                AppColors.xpGold,
                AppColors.streakFire,
                AppColors.levelPurple,
                AppColors.achievementEmerald,
                AppColors.primaryLight,
                AppColors.success,
              ],
              createParticlePath: _drawStar,
            ),
          ),
        ),

        Positioned(
          top: top + 8,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _bannerController,
            builder: (context, child) {
              if (_bannerController.isDismissed) return const SizedBox.shrink();
              return Transform.translate(
                offset: Offset(0, _bannerSlide.value * 80),
                child: Opacity(
                  opacity: _bannerFade.value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _bannerGradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_bannerGradient.first).withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_bannerIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _bannerText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_bannerSubtext.isNotEmpty)
                          Text(
                            _bannerSubtext,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Path _drawStar(Size size) {
  final path = Path();
  final r = size.width / 2;
  const points = 5;
  final angle = pi / points;

  for (var i = 0; i < 2 * points; i++) {
    final radius = i.isEven ? r : r / 2;
    final x = r + radius * cos(i * angle - pi / 2);
    final y = r + radius * sin(i * angle - pi / 2);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

class _CelebrationConfig {
  final IconData icon;
  final List<Color> gradient;
  const _CelebrationConfig(this.icon, this.gradient);
}
