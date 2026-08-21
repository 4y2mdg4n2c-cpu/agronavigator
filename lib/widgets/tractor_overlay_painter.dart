import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Экранный маркер техники.
///
/// [tractorAnchor] уже содержит экранную проекцию текущей GPS-точки.
/// Поворот и экранный размер самого значка остаются фиксированными.
class TractorOverlayPainter extends CustomPainter {
  final Offset tractorAnchor;
  final double implementWidth;

  const TractorOverlayPainter({
    required this.tractorAnchor,
    required this.implementWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    _drawDirectionMarker(canvas, size);
    _drawTractor(canvas, size);
  }

  void _drawDirectionMarker(Canvas canvas, Size size) {
    final markerSize = (size.shortestSide * 0.032).clamp(20.0, 30.0);
    final tipY = tractorAnchor.dy - markerSize * 2.55;
    final marker = Path()
      ..moveTo(tractorAnchor.dx, tipY)
      ..lineTo(tractorAnchor.dx - markerSize * 0.52, tipY + markerSize * 0.92)
      ..lineTo(tractorAnchor.dx, tipY + markerSize * 0.72)
      ..lineTo(tractorAnchor.dx + markerSize * 0.52, tipY + markerSize * 0.92)
      ..close();

    canvas.drawPath(
      marker.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      marker,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FFF6), Color(0xFFB9C9B4)],
        ).createShader(marker.getBounds()),
    );
  }

  void _drawTractor(Canvas canvas, Size size) {
    final tractorWidth = (size.shortestSide * 0.072).clamp(58.0, 82.0);
    final unit = tractorWidth / 72;
    final fixedImplementWidth = implementWidth.isFinite && implementWidth > 0
        ? implementWidth
        : 76 * unit;

    canvas.save();
    canvas.translate(tractorAnchor.dx, tractorAnchor.dy + 2 * unit);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 12 * unit),
        width: 76 * unit,
        height: 72 * unit,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * unit),
    );

    _drawImplement(canvas, unit, fixedImplementWidth);
    _drawTractorWheels(canvas, unit);
    _drawTractorBody(canvas, unit);

    canvas.restore();
  }

  void _drawImplement(Canvas canvas, double unit, double fixedImplementWidth) {
    final supportPaint = Paint()
      ..color = const Color(0xFF394936)
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, 24 * unit), Offset(0, 35 * unit), supportPaint);

    final implementRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, 42 * unit),
        width: fixedImplementWidth,
        height: 25 * unit,
      ),
      Radius.circular(6 * unit),
    );
    canvas.drawRRect(
      implementRect.shift(Offset(0, 4 * unit)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * unit),
    );
    canvas.drawRRect(
      implementRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF493D), Color(0xFFD91F24)],
        ).createShader(implementRect.outerRect),
    );

    final guardPaint = Paint()
      ..color = const Color(0xFFFFA516)
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-fixedImplementWidth * 0.4, 37 * unit),
      Offset(fixedImplementWidth * 0.4, 35 * unit),
      guardPaint,
    );
    final tineCount = math.max(3, (fixedImplementWidth / (10 * unit)).round());
    final tineSpacing = fixedImplementWidth / (tineCount + 1);
    for (var index = 1; index <= tineCount; index++) {
      final x = -fixedImplementWidth / 2 + tineSpacing * index;
      canvas.drawLine(
        Offset(x, 51 * unit),
        Offset(x + 2 * unit, 56 * unit),
        Paint()
          ..color = const Color(0xFF263029)
          ..strokeWidth = 3 * unit
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawTractorWheels(Canvas canvas, double unit) {
    final tyrePaint = Paint()..color = const Color(0xFF202522);
    final treadPaint = Paint()
      ..color = const Color(0xFF4A514C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit;

    final wheelRects = [
      Rect.fromCenter(
        center: Offset(-27 * unit, 10 * unit),
        width: 15 * unit,
        height: 31 * unit,
      ),
      Rect.fromCenter(
        center: Offset(27 * unit, 10 * unit),
        width: 15 * unit,
        height: 31 * unit,
      ),
      Rect.fromCenter(
        center: Offset(-22 * unit, -24 * unit),
        width: 10 * unit,
        height: 22 * unit,
      ),
      Rect.fromCenter(
        center: Offset(22 * unit, -24 * unit),
        width: 10 * unit,
        height: 22 * unit,
      ),
    ];

    for (final rect in wheelRects) {
      final wheel = RRect.fromRectAndRadius(rect, Radius.circular(5 * unit));
      canvas.drawRRect(wheel, tyrePaint);
      canvas.drawRRect(wheel.deflate(2 * unit), treadPaint);
    }
  }

  void _drawTractorBody(Canvas canvas, double unit) {
    final body = Path()
      ..moveTo(-17 * unit, 24 * unit)
      ..lineTo(-19 * unit, -18 * unit)
      ..quadraticBezierTo(-16 * unit, -37 * unit, 0, -42 * unit)
      ..quadraticBezierTo(16 * unit, -37 * unit, 19 * unit, -18 * unit)
      ..lineTo(17 * unit, 24 * unit)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF4B9618), Color(0xFFA9D735), Color(0xFF3C8614)],
          stops: [0, 0.48, 1],
        ).createShader(body.getBounds()),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF315F18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * unit,
    );

    final cabin = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -12 * unit),
        width: 29 * unit,
        height: 27 * unit,
      ),
      Radius.circular(7 * unit),
    );
    canvas.drawRRect(cabin, Paint()..color = const Color(0xFF153B3B));
    canvas.drawRRect(
      cabin.deflate(3 * unit),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBEE5E0), Color(0xFF3F7774)],
        ).createShader(cabin.outerRect),
    );

    final hood = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -31 * unit),
        width: 20 * unit,
        height: 21 * unit,
      ),
      Radius.circular(7 * unit),
    );
    canvas.drawRRect(hood, Paint()..color = const Color(0xFF82C624));
    canvas.drawLine(
      Offset(0, -39 * unit),
      Offset(0, -24 * unit),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2 * unit
        ..strokeCap = StrokeCap.round,
    );

    final hubPaint = Paint()..color = const Color(0xFFE9D83F);
    canvas.drawCircle(Offset(-20 * unit, 19 * unit), 3.5 * unit, hubPaint);
    canvas.drawCircle(Offset(20 * unit, 19 * unit), 3.5 * unit, hubPaint);
  }

  @override
  bool shouldRepaint(covariant TractorOverlayPainter oldDelegate) {
    return tractorAnchor != oldDelegate.tractorAnchor ||
        implementWidth != oldDelegate.implementWidth;
  }
}
