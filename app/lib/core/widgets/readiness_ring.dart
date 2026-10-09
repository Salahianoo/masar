import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Big readiness %. The ring and the number animate whenever [value] changes.
class ReadinessRing extends StatelessWidget {
  const ReadinessRing({
    super.key,
    required this.value,
    this.size = 168,
    this.label,
    this.color = AppColors.primary,
  });

  /// 0..100
  final int value;
  final double size;

  /// Optional line under the number, e.g. «جاهزيتك للامتحان».
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final stroke = size * 0.075;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 100).toDouble()),
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(progress: v / 100, color: color, stroke: stroke),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(stroke * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    child: Text(
                      '${v.round()}%',
                      style: AppText.display.copyWith(fontSize: size * 0.24),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  if (label != null)
                    Text(
                      label!,
                      style: AppText.caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.stroke});

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, track);
    if (progress > 0) {
      // RTL app: start at the top and fill counter-clockwise (toward the reading direction)
      canvas.drawArc(arcRect, -math.pi / 2, -2 * math.pi * progress, false, fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
