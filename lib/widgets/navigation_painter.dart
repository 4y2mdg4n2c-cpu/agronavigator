import 'dart:math' as math;

import 'package:agronavigator_app/models/xy_point.dart';
import 'package:flutter/material.dart';

class NavigationPainter extends CustomPainter {
  final List<XYPoint> firstPass;
  final List<List<XYPoint>> guidanceLines;
  final List<List<XYPoint>> coveragePolygons;
  final XYPoint? currentPoint;
  final double gpsHeading;
  final double scale;
  final Offset viewOffset;
  final double pixelsPerMeter;
  final Offset tractorAnchor;

  /// Поворот относится только к экранному представлению. Исходная локальная
  /// система XY и списки навигационной геометрии остаются неизменными.
  final bool rotateWithGpsHeading;

  NavigationPainter({
    required this.firstPass,
    required this.guidanceLines,
    required this.coveragePolygons,
    required this.currentPoint,
    required this.scale,
    required this.viewOffset,
    required this.pixelsPerMeter,
    required this.tractorAnchor,
    this.gpsHeading = -1,
    this.rotateWithGpsHeading = false,
  });

  static const Color _fieldNearColor = Color(0xFFE5F2D7);
  static const Color _fieldFarColor = Color(0xFFD3E9C3);
  static const Color _coverageColor = Color(0xFF4D8FEA);
  static const Color _coverageBorderColor = Color(0xFF2B72D7);
  static const Color _guidanceColor = Color(0xFF7E8C91);
  static const Color _firstPassColor = Color(0xFFFF8A00);
  static const double _perspectiveStrength = 0.60;

  XYPoint get _worldCenter => currentPoint ?? const XYPoint(x: 0, y: 0);

  double get _headingRadians {
    if (!rotateWithGpsHeading || !gpsHeading.isFinite || gpsHeading < 0) {
      return 0;
    }
    return gpsHeading * math.pi / 180;
  }

  Offset _sceneAnchor() {
    return Offset(
      tractorAnchor.dx + viewOffset.dx,
      tractorAnchor.dy + viewOffset.dy,
    );
  }

  double _horizonY(Size size) {
    return size.height * (size.height > size.width ? 0.16 : 0.13);
  }

  double _horizontalPerspective(Size size) {
    return size.height > size.width ? 1.55 : 1.20;
  }

  double _projectionPixelsPerMeter() {
    // Базовая проекция не зависит от pinch. Zoom применяется к уже
    // спроецированным смещениям единым экранным коэффициентом.
    if (!scale.isFinite || scale <= 0) {
      return pixelsPerMeter;
    }
    return pixelsPerMeter / scale;
  }

  double _perspectiveDistance(Size size) {
    return math.max(tractorAnchor.dy - _horizonY(size), 1.0);
  }

  /// Проецирует готовую XY-точку на экранную плоскость с перспективным
  /// сокращением по направлению движения. Это только отображение: координаты
  /// точки и навигационные коллекции не изменяются.
  Offset toScreen(XYPoint point, Size size) {
    final center = _worldCenter;
    final dx = point.x - center.x;
    final dy = point.y - center.y;
    final heading = _headingRadians;

    // GPS heading: 0° — север (+Y), 90° — восток (+X).
    final lateral = dx * math.cos(heading) - dy * math.sin(heading);
    final forward = dx * math.sin(heading) + dy * math.cos(heading);

    final anchor = _sceneAnchor();
    final perspectiveDistance = _perspectiveDistance(size);
    final projectionPixelsPerMeter = _projectionPixelsPerMeter();
    final baseForwardPixels =
        forward * projectionPixelsPerMeter * _perspectiveStrength;

    // Точки далеко позади камеры всё равно находятся ниже видимой области.
    // Ограничение защищает проекцию от перехода через ближнюю плоскость.
    final forwardPixels = math.max(
      baseForwardPixels,
      -perspectiveDistance * 0.62,
    );
    final depthScale =
        perspectiveDistance / (perspectiveDistance + forwardPixels);
    final horizontalScale = depthScale * _horizontalPerspective(size);
    final screenZoom = scale.isFinite && scale > 0 ? scale : 1.0;

    // Оба смещения масштабируются одинаково, поэтому pinch не меняет форму
    // перспективы и только приближает или отдаляет готовую экранную сцену.
    return Offset(
      anchor.dx +
          lateral * projectionPixelsPerMeter * horizontalScale * screenZoom,
      anchor.dy - forwardPixels * depthScale * screenZoom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    _drawFieldBackground(canvas, size);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawCoverage(canvas, size);
    _drawGuidanceLines(canvas, size);
    _drawFirstPass(canvas, size);
    canvas.restore();
  }

  void _drawFieldBackground(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fieldFarColor, _fieldNearColor],
          stops: [0, 1],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.translate(viewOffset.dx, viewOffset.dy);

    final horizonY = _horizonY(size);
    _drawSoftVegetation(canvas, size, horizonY);

    final hazeRect = Rect.fromLTWH(0, horizonY - 20, size.width, 54);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(hazeRect),
    );
    canvas.restore();
  }

  void _drawSoftVegetation(Canvas canvas, Size size, double horizonY) {
    final edgeWidth = math.min(size.width * 0.085, 96.0);
    final edgePaint = Paint()
      ..color = const Color(0xFF78AF61).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final left = Path()..moveTo(0, horizonY - 20);
    final right = Path()..moveTo(size.width, horizonY - 20);
    const steps = 16;
    for (var index = 0; index <= steps; index++) {
      final t = index / steps;
      final y = horizonY - 20 + (size.height - horizonY + 20) * t;
      final width = edgeWidth * (0.25 + 0.75 * t);
      final wobble = math.sin(index * 1.71) * edgeWidth * 0.08;
      left.lineTo(width + wobble, y);
      right.lineTo(size.width - width - wobble, y);
    }
    left
      ..lineTo(0, size.height)
      ..close();
    right
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(left, edgePaint);
    canvas.drawPath(right, edgePaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF5F9D54).withValues(alpha: 0.09);
    for (var index = 0; index < 22; index++) {
      final t = (index + 0.5) / 22;
      final y = horizonY + (size.height - horizonY) * t;
      final radius = 4 + 14 * t;
      final inset = edgeWidth * (0.18 + 0.5 * t);
      final stagger = math.sin(index * 2.2) * radius * 0.9;
      canvas.drawCircle(Offset(inset + stagger, y), radius, leafPaint);
      canvas.drawCircle(
        Offset(size.width - inset - stagger, y + radius * 0.35),
        radius,
        leafPaint,
      );
    }
  }

  void _drawCoverage(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = _coverageColor.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final borderPaint = Paint()
      ..color = _coverageBorderColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final polygon in coveragePolygons) {
      if (polygon.length < 3) {
        continue;
      }
      final path = _projectedPath(polygon, size, close: true);
      if (!_isVisible(path, size)) {
        continue;
      }
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawGuidanceLines(Canvas canvas, Size size) {
    final guidancePaint = Paint()
      ..color = _guidanceColor.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final line in guidanceLines) {
      if (line.length < 2) {
        continue;
      }
      final path = _projectedPath(line, size);
      if (!_isVisible(path, size)) {
        continue;
      }
      _drawDashedPath(canvas, path, guidancePaint, dash: 9, gap: 8);
    }
  }

  void _drawFirstPass(Canvas canvas, Size size) {
    if (firstPass.length < 2) {
      return;
    }
    final path = _projectedPath(firstPass, size);
    if (!_isVisible(path, size)) {
      return;
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7D5A24).withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _firstPassColor.withValues(alpha: 0.94)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  Path _projectedPath(List<XYPoint> points, Size size, {bool close = false}) {
    final first = toScreen(points.first, size);
    final path = Path()..moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      final projected = toScreen(point, size);
      path.lineTo(projected.dx, projected.dy);
    }
    if (close) {
      path.close();
    }
    return path;
  }

  bool _isVisible(Path path, Size size) {
    final viewport = Rect.fromLTRB(-48, -48, size.width + 48, size.height + 48);
    return path.getBounds().overlaps(viewport);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dash, metric.length),
          ),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant NavigationPainter oldDelegate) {
    // Навигационные списки пополняются на месте во время GPS-трека, поэтому
    // сравнение ссылок не обнаружит все визуальные изменения.
    return true;
  }
}
