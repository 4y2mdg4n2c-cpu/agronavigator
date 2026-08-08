import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/widgets/navigation_painter.dart';
import 'package:flutter/material.dart';

class NavigationCanvas extends StatefulWidget {
  final List<XYPoint> firstPass;
  final List<List<XYPoint>> guidanceLines;
  final List<XYPoint> coveragePolygon;
  final XYPoint? currentPoint;
  final double gpsHeading;

  /// Задел для режима "курс вверх". По умолчанию север остаётся сверху.
  final bool rotateWithGpsHeading;

  const NavigationCanvas({
    super.key,
    required this.firstPass,
    required this.guidanceLines,
    required this.coveragePolygon,
    required this.currentPoint,
    this.gpsHeading = -1,
    this.rotateWithGpsHeading = false,
  });

  @override
  State<NavigationCanvas> createState() => _NavigationCanvasState();
}

class _NavigationCanvasState extends State<NavigationCanvas> {
  static const double _basePixelsPerMeter = 2.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;

  double _scale = 1.0;
  Offset _viewOffset = Offset.zero;
  double? _smoothHeading;

  double _scaleAtGestureStart = 1.0;
  Offset _viewOffsetAtGestureStart = Offset.zero;
  Offset _focalPointAtGestureStart = Offset.zero;
  Size _canvasSize = Size.zero;

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleAtGestureStart = _scale;
    _viewOffsetAtGestureStart = _viewOffset;
    _focalPointAtGestureStart = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newScale = (_scaleAtGestureStart * details.scale)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final scaleRatio = newScale / _scaleAtGestureStart;
    final viewAnchor = details.localFocalPoint;
    final tractorAnchor = Offset(
      _canvasSize.width / 2,
      _canvasSize.height * 0.68,
    );

    setState(() {
      // При pinch точка под пальцами остаётся на месте. Смещение применяется
      // только к экранному представлению, а не к XY-координатам навигации.
      _scale = newScale;
      _viewOffset =
          viewAnchor -
          tractorAnchor -
          (_focalPointAtGestureStart -
                  tractorAnchor -
                  _viewOffsetAtGestureStart) *
              scaleRatio;
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _viewOffset = Offset.zero;
    });
  }

  double _filterHeading(double newHeading) {
    if (!newHeading.isFinite || newHeading < 0) {
      return _smoothHeading ?? newHeading;
    }

    final normalizedHeading = newHeading % 360;
    if (_smoothHeading == null) {
      return _smoothHeading = normalizedHeading;
    }

    final difference = (normalizedHeading - _smoothHeading! + 540) % 360 - 180;
    if (difference.abs() < 5) {
      return _smoothHeading!;
    }

    _smoothHeading = (_smoothHeading! + difference * 0.25 + 360) % 360;
    return _smoothHeading!;
  }

  @override
  Widget build(BuildContext context) {
    final displayHeading = _filterHeading(widget.gpsHeading);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onDoubleTap: _resetView,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _canvasSize = constraints.biggest;
          return CustomPaint(
            painter: NavigationPainter(
              firstPass: widget.firstPass,
              guidanceLines: widget.guidanceLines,
              coveragePolygon: widget.coveragePolygon,
              currentPoint: widget.currentPoint,
              gpsHeading: displayHeading,
              rotateWithGpsHeading: widget.rotateWithGpsHeading,
              scale: _scale,
              viewOffset: _viewOffset,
              pixelsPerMeter: _basePixelsPerMeter * _scale,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
