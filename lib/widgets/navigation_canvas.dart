import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/widgets/navigation_painter.dart';
import 'package:agronavigator_app/widgets/tractor_overlay_painter.dart';
import 'package:flutter/material.dart';

class NavigationCanvas extends StatefulWidget {
  final List<XYPoint> firstPass;
  final List<List<XYPoint>> guidanceLines;
  final List<List<XYPoint>> coveragePolygons;
  final XYPoint? currentPoint;

  /// Используется только для экранной ширины рабочего агрегата.
  final double workingWidth;
  final double gpsHeading;

  /// Задел для режима "курс вверх". По умолчанию север остаётся сверху.
  final bool rotateWithGpsHeading;

  const NavigationCanvas({
    super.key,
    required this.firstPass,
    required this.guidanceLines,
    required this.coveragePolygons,
    required this.currentPoint,
    required this.workingWidth,
    this.gpsHeading = -1,
    this.rotateWithGpsHeading = false,
  });

  @override
  State<NavigationCanvas> createState() => _NavigationCanvasState();
}

class _NavigationCanvasState extends State<NavigationCanvas> {
  static const double _basePixelsPerMeter = 4.25;
  static const double _minScale = 0.25;
  static const double _maxScale = 4.0;
  static const double _portraitImplementPixelsPerMeter = 6.5875;
  static const double _landscapeImplementPixelsPerMeter = 5.10;
  static const double _portraitTractorAnchorY = 0.69;
  static const double _landscapeTractorAnchorY = 0.72;

  double _scale = 1.0;
  Offset _viewOffset = Offset.zero;
  double? _smoothHeading;

  double _scaleAtGestureStart = 1.0;
  Offset _viewOffsetAtGestureStart = Offset.zero;
  Offset _focalPointAtGestureStart = Offset.zero;
  Size _canvasSize = Size.zero;

  Offset _tractorAnchor(Size size) {
    final verticalPosition = size.height > size.width
        ? _portraitTractorAnchorY
        : _landscapeTractorAnchorY;
    return Offset(size.width / 2, size.height * verticalPosition);
  }

  double _fixedImplementWidth(Size size) {
    final fixedPixelsPerMeter = size.height > size.width
        ? _portraitImplementPixelsPerMeter
        : _landscapeImplementPixelsPerMeter;
    return widget.workingWidth * fixedPixelsPerMeter;
  }

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
    final tractorAnchor = _tractorAnchor(_canvasSize);

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
          final tractorAnchor = _tractorAnchor(_canvasSize);
          final tractorScreenPosition = tractorAnchor + _viewOffset;
          return CustomPaint(
            painter: NavigationPainter(
              firstPass: widget.firstPass,
              guidanceLines: widget.guidanceLines,
              coveragePolygons: widget.coveragePolygons,
              currentPoint: widget.currentPoint,
              gpsHeading: displayHeading,
              rotateWithGpsHeading: widget.rotateWithGpsHeading,
              scale: _scale,
              viewOffset: _viewOffset,
              pixelsPerMeter: _basePixelsPerMeter * _scale,
              tractorAnchor: tractorAnchor,
            ),
            foregroundPainter: TractorOverlayPainter(
              tractorAnchor: tractorScreenPosition,
              implementWidth: _fixedImplementWidth(_canvasSize),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
