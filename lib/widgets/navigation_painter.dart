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

  /// Пока экран остаётся ориентированным на север. Флаг и курс передаются
  /// отдельно, чтобы поворот по GPS можно было включить без изменения
  /// координатной системы или геометрических расчётов.
  final bool rotateWithGpsHeading;

  NavigationPainter({
    required this.firstPass,
    required this.guidanceLines,
    required this.coveragePolygons,
    required this.currentPoint,
    required this.scale,
    required this.viewOffset,
    required this.pixelsPerMeter,
    this.gpsHeading = -1,
    this.rotateWithGpsHeading = false,
  });

  static const Color _backgroundColor = Color(0xFFE0F2D8);
  static const Color _coverageColor = Color(0xFF1976D2);
  static const Color _guidanceColor = Color(0xFF29B6F6);
  static const Color _firstPassColor = Color(0xFFFFB300);

  /// Переводит локальные метры XY в координаты холста.
  ///
  /// [currentPoint] находится в нижней части рабочей области. Инверсия оси Y нужна,
  /// потому что в XY север направлен вверх, а на Canvas ось Y направлена вниз.
  Offset toScreen(XYPoint point, Size size) {
    final center = currentPoint ?? const XYPoint(x: 0, y: 0);
    final dx = point.x - center.x;
    final dy = point.y - center.y;

    return Offset(
      size.width / 2 + viewOffset.dx + dx * pixelsPerMeter,
      size.height * 0.68 + viewOffset.dy - dy * pixelsPerMeter,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _backgroundColor);

    final coveragePaint = Paint()
      ..color = _coverageColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final coverageBorderPaint = Paint()
      ..color = _coverageColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final guidancePaint = Paint()
      ..color = _guidanceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final firstPassPaint = Paint()
      ..color = _firstPassColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Все данные отображаются в метрах локальной XY-системы. Трансформация
    // перемещает только их представление на Canvas, не меняя исходные данные.
    final shouldRotate =
        rotateWithGpsHeading && gpsHeading.isFinite && gpsHeading >= 0;
    final rotation = shouldRotate ? -gpsHeading * math.pi / 180 : 0.0;

    canvas.save();
    canvas.translate(
      size.width / 2 + viewOffset.dx,
      size.height * 0.68 + viewOffset.dy,
    );
    canvas.rotate(rotation);
    canvas.scale(pixelsPerMeter, -pixelsPerMeter);

    final center = currentPoint ?? const XYPoint(x: 0, y: 0);
    canvas.translate(-center.x, -center.y);

    for (final polygon in coveragePolygons) {
      _drawPolygon(canvas, polygon, coveragePaint, coverageBorderPaint);
    }
    for (final line in guidanceLines) {
      _drawLine(canvas, line, guidancePaint);
    }
    _drawLine(canvas, firstPass, firstPassPaint);
    canvas.restore();

    _drawTractor(canvas, size);
  }

  void _drawPolygon(
    Canvas canvas,
    List<XYPoint> points,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    if (points.length < 3) {
      return;
    }

    final path = _pathFromPoints(points, close: true);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawLine(Canvas canvas, List<XYPoint> points, Paint paint) {
    if (points.length < 2) {
      return;
    }
    canvas.drawPath(_pathFromPoints(points), paint);
  }

  Path _pathFromPoints(List<XYPoint> points, {bool close = false}) {
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (final point in points.skip(1)) {
      path.lineTo(point.x, point.y);
    }
    if (close) {
      path.close();
    }
    return path;
  }

  void _drawTractor(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + viewOffset.dx,
      size.height * 0.68 + viewOffset.dy,
    );
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(center, 7, Paint()..color = Colors.red);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = const Color(0xFF8B0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant NavigationPainter oldDelegate) {
    // Списки навигации пополняются на месте во время GPS-трека. Поэтому
    // сравнение ссылок здесь ненадёжно: старый painter видит те же списки.
    return true;
  }
}
