import 'dart:math';
import 'package:flutter/material.dart';

/// Illustration for empty states showing an empty inbox/box.
class EmptyBoxIllustration extends StatelessWidget {
  final double size;
  const EmptyBoxIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EmptyBoxPainter(primary, surface)),
    );
  }
}

class _EmptyBoxPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _EmptyBoxPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bgPaint = Paint()..color = surface;
    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, bgPaint);

    final boxPaint = Paint()
      ..color = primary.withAlpha(40)
      ..style = PaintingStyle.fill;
    final boxStroke = Paint()
      ..color = primary.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.55), width: w * 0.5, height: w * 0.35),
      const Radius.circular(8),
    );
    canvas.drawRRect(box, boxPaint);
    canvas.drawRRect(box, boxStroke);

    final flapPath = Path()
      ..moveTo(cx - w * 0.28, h * 0.38)
      ..lineTo(cx - w * 0.1, h * 0.28)
      ..lineTo(cx + w * 0.1, h * 0.28)
      ..lineTo(cx + w * 0.28, h * 0.38);
    canvas.drawPath(flapPath, boxStroke);

    final dotPaint = Paint()..color = primary.withAlpha(60);
    canvas.drawCircle(Offset(cx - w * 0.15, h * 0.2), 3, dotPaint);
    canvas.drawCircle(Offset(cx + w * 0.2, h * 0.22), 3, dotPaint);
    canvas.drawCircle(Offset(cx, h * 0.15), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for chat empty state - speech bubbles.
class ChatBubblesIllustration extends StatelessWidget {
  final double size;
  const ChatBubblesIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChatBubblesPainter(primary, surface)),
    );
  }
}

class _ChatBubblesPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _ChatBubblesPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()..color = surface;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.4, bgPaint);

    final bubblePaint1 = Paint()..color = primary.withAlpha(50);
    final bubbleStroke1 = Paint()
      ..color = primary.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.25, w * 0.45, h * 0.22),
        const Radius.circular(12),
      ),
      bubblePaint1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.25, w * 0.45, h * 0.22),
        const Radius.circular(12),
      ),
      bubbleStroke1,
    );

    final linePaint = Paint()
      ..color = primary.withAlpha(60)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.22, h * 0.33), Offset(w * 0.5, h * 0.33), linePaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.40), Offset(w * 0.42, h * 0.40), linePaint);

    final bubblePaint2 = Paint()..color = primary.withAlpha(30);
    final bubbleStroke2 = Paint()
      ..color = primary.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.52, w * 0.5, h * 0.2),
        const Radius.circular(12),
      ),
      bubblePaint2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.52, w * 0.5, h * 0.2),
        const Radius.circular(12),
      ),
      bubbleStroke2,
    );

    canvas.drawLine(Offset(w * 0.42, h * 0.60), Offset(w * 0.75, h * 0.60), linePaint);
    canvas.drawLine(Offset(w * 0.42, h * 0.66), Offset(w * 0.65, h * 0.66), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for achievement/trophy.
class TrophyIllustration extends StatelessWidget {
  final double size;
  const TrophyIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TrophyPainter(primary, surface)),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _TrophyPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bgPaint = Paint()..color = surface;
    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, bgPaint);

    final accent = primary;
    final cupFill = Paint()..color = accent.withAlpha(50);
    final cupStroke = Paint()
      ..color = accent.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cupPath = Path()
      ..moveTo(cx - w * 0.18, h * 0.28)
      ..lineTo(cx - w * 0.14, h * 0.52)
      ..quadraticBezierTo(cx, h * 0.62, cx + w * 0.14, h * 0.52)
      ..lineTo(cx + w * 0.18, h * 0.28)
      ..close();
    canvas.drawPath(cupPath, cupFill);
    canvas.drawPath(cupPath, cupStroke);

    canvas.drawLine(Offset(cx, h * 0.55), Offset(cx, h * 0.65), cupStroke);

    final basePath = Path()
      ..moveTo(cx - w * 0.12, h * 0.65)
      ..lineTo(cx + w * 0.12, h * 0.65)
      ..lineTo(cx + w * 0.1, h * 0.7)
      ..lineTo(cx - w * 0.1, h * 0.7)
      ..close();
    canvas.drawPath(basePath, cupFill);
    canvas.drawPath(basePath, cupStroke);

    final handleStroke = Paint()
      ..color = accent.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.22, h * 0.38), width: w * 0.12, height: h * 0.15),
      pi * 0.5, pi, false, handleStroke,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + w * 0.22, h * 0.38), width: w * 0.12, height: h * 0.15),
      -pi * 0.5, pi, false, handleStroke,
    );

    final starPaint = Paint()..color = accent.withAlpha(140);
    _drawSmallStar(canvas, Offset(cx, h * 0.39), 6, starPaint);
    _drawSmallStar(canvas, Offset(cx - w * 0.25, h * 0.2), 3, Paint()..color = accent.withAlpha(60));
    _drawSmallStar(canvas, Offset(cx + w * 0.28, h * 0.22), 3, Paint()..color = accent.withAlpha(50));
  }

  void _drawSmallStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const points = 5;
    final angle = pi / points;
    for (var i = 0; i < 2 * points; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final x = center.dx + radius * cos(i * angle - pi / 2);
      final y = center.dy + radius * sin(i * angle - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for calendar/schedule empty state.
class CalendarIllustration extends StatelessWidget {
  final double size;
  const CalendarIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CalendarPainter(primary, surface)),
    );
  }
}

class _CalendarPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _CalendarPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, Paint()..color = surface);

    final cardFill = Paint()..color = primary.withAlpha(30);
    final cardStroke = Paint()
      ..color = primary.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.5), width: w * 0.55, height: h * 0.5),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, cardFill);
    canvas.drawRRect(rect, cardStroke);

    final headerFill = Paint()..color = primary.withAlpha(60);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - w * 0.275, h * 0.25, w * 0.55, h * 0.1),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      headerFill,
    );

    final dotPaint = Paint()..color = primary.withAlpha(50);
    final accentDot = Paint()..color = primary.withAlpha(120);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final dx = cx - w * 0.17 + col * (w * 0.12);
        final dy = h * 0.42 + row * (h * 0.1);
        final paint = (row == 1 && col == 2) ? accentDot : dotPaint;
        canvas.drawCircle(Offset(dx, dy), 3, paint);
      }
    }

    final clipPaint = Paint()
      ..color = primary.withAlpha(100)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - w * 0.12, h * 0.22), Offset(cx - w * 0.12, h * 0.28), clipPaint);
    canvas.drawLine(Offset(cx + w * 0.12, h * 0.22), Offset(cx + w * 0.12, h * 0.28), clipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for books/learning resources.
class BooksIllustration extends StatelessWidget {
  final double size;
  const BooksIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BooksPainter(primary, surface)),
    );
  }
}

class _BooksPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _BooksPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, Paint()..color = surface);

    _drawBook(canvas, Offset(cx - w * 0.08, h * 0.55), w * 0.18, h * 0.3,
        primary.withAlpha(60), primary.withAlpha(140));
    _drawBook(canvas, Offset(cx + w * 0.05, h * 0.53), w * 0.16, h * 0.32,
        primary.withAlpha(40), primary.withAlpha(100));
    _drawBook(canvas, Offset(cx + w * 0.16, h * 0.56), w * 0.14, h * 0.28,
        primary.withAlpha(50), primary.withAlpha(120));
  }

  void _drawBook(Canvas canvas, Offset center, double w, double h,
      Color fill, Color stroke) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = fill);
    canvas.drawRRect(rect, Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for grades/academic screens.
class GraduationCapIllustration extends StatelessWidget {
  final double size;
  const GraduationCapIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GraduationCapPainter(primary, surface)),
    );
  }
}

class _GraduationCapPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _GraduationCapPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, Paint()..color = surface);

    final capFill = Paint()..color = primary.withAlpha(50);
    final capStroke = Paint()
      ..color = primary.withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final capTop = Path()
      ..moveTo(cx, h * 0.25)
      ..lineTo(cx + w * 0.3, h * 0.4)
      ..lineTo(cx, h * 0.5)
      ..lineTo(cx - w * 0.3, h * 0.4)
      ..close();
    canvas.drawPath(capTop, capFill);
    canvas.drawPath(capTop, capStroke);

    final boardFill = Paint()..color = primary.withAlpha(70);
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.22, h * 0.5, w * 0.44, h * 0.08),
      boardFill,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.22, h * 0.5, w * 0.44, h * 0.08),
      capStroke,
    );

    final tassel = Paint()
      ..color = primary.withAlpha(120)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + w * 0.3, h * 0.4), Offset(cx + w * 0.32, h * 0.62), tassel);
    canvas.drawCircle(Offset(cx + w * 0.32, h * 0.64), 3, Paint()..color = primary.withAlpha(120));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for clipboard/checklist (attendance, sync, feedback).
class ClipboardIllustration extends StatelessWidget {
  final double size;
  const ClipboardIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClipboardPainter(primary, surface)),
    );
  }
}

class _ClipboardPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _ClipboardPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, Paint()..color = surface);

    final boardFill = Paint()..color = primary.withAlpha(30);
    final boardStroke = Paint()
      ..color = primary.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.52), width: w * 0.48, height: h * 0.52),
      const Radius.circular(6),
    );
    canvas.drawRRect(board, boardFill);
    canvas.drawRRect(board, boardStroke);

    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.27), width: w * 0.2, height: h * 0.06),
      const Radius.circular(3),
    );
    canvas.drawRRect(clipRect, Paint()..color = primary.withAlpha(80));

    final checkPaint = Paint()
      ..color = primary.withAlpha(100)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = primary.withAlpha(50)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final y = h * 0.38 + i * (h * 0.12);
      canvas.drawLine(Offset(cx - w * 0.12, y), Offset(cx - w * 0.06, y + 4), checkPaint);
      canvas.drawLine(Offset(cx - w * 0.06, y + 4), Offset(cx - w * 0.02, y - 2), checkPaint);
      canvas.drawLine(Offset(cx + w * 0.04, y), Offset(cx + w * 0.18, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for AI/brain.
class BrainIllustration extends StatelessWidget {
  final double size;
  const BrainIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrainPainter(primary, surface)),
    );
  }
}

class _BrainPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  _BrainPainter(this.primary, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawCircle(Offset(cx, h * 0.5), w * 0.4, Paint()..color = surface);

    final stroke = Paint()
      ..color = primary.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = primary.withAlpha(30);

    final path = Path()
      ..moveTo(cx, h * 0.28)
      ..cubicTo(cx - w * 0.22, h * 0.25, cx - w * 0.28, h * 0.42, cx - w * 0.15, h * 0.5)
      ..cubicTo(cx - w * 0.28, h * 0.55, cx - w * 0.22, h * 0.72, cx, h * 0.7)
      ..cubicTo(cx + w * 0.22, h * 0.72, cx + w * 0.28, h * 0.55, cx + w * 0.15, h * 0.5)
      ..cubicTo(cx + w * 0.28, h * 0.42, cx + w * 0.22, h * 0.25, cx, h * 0.28)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final center = Paint()
      ..color = primary.withAlpha(60)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, h * 0.32), Offset(cx, h * 0.66), center);

    final dot = Paint()..color = primary.withAlpha(80);
    canvas.drawCircle(Offset(cx - w * 0.1, h * 0.42), 3, dot);
    canvas.drawCircle(Offset(cx + w * 0.1, h * 0.44), 3, dot);
    canvas.drawCircle(Offset(cx - w * 0.08, h * 0.58), 3, dot);
    canvas.drawCircle(Offset(cx + w * 0.12, h * 0.56), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
