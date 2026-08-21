import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/widgets/navigation_canvas.dart';
import 'package:agronavigator_app/widgets/navigation_painter.dart';
import 'package:agronavigator_app/widgets/tractor_overlay_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currentPoint = XYPoint(x: 0, y: 0);
  const workingWidth = 12.0;

  NavigationPainter createPainter({
    required double scale,
    required Size size,
    double heading = 0,
    Offset viewOffset = Offset.zero,
  }) {
    final tractorVerticalPosition = size.height > size.width ? 0.69 : 0.72;
    return NavigationPainter(
      firstPass: const [],
      guidanceLines: const [],
      coveragePolygons: const [],
      currentPoint: currentPoint,
      gpsHeading: heading,
      rotateWithGpsHeading: true,
      scale: scale,
      viewOffset: viewOffset,
      pixelsPerMeter: 4.25 * scale,
      tractorAnchor: Offset(
        size.width / 2,
        size.height * tractorVerticalPosition,
      ),
    );
  }

  test('pinch zoom scales an unchanged perspective profile', () {
    const sizes = [Size(1200, 700), Size(700, 1200)];
    const worldPoint = XYPoint(x: 14, y: 85);

    for (final size in sizes) {
      final basePainter = createPainter(scale: 1, size: size);
      final baseAnchor = basePainter.toScreen(currentPoint, size);
      final basePoint = basePainter.toScreen(worldPoint, size);
      final baseOffset = basePoint - baseAnchor;

      for (final zoom in [0.25, 2.0, 4.0]) {
        final zoomedPainter = createPainter(scale: zoom, size: size);
        final zoomedAnchor = zoomedPainter.toScreen(currentPoint, size);
        final zoomedPoint = zoomedPainter.toScreen(worldPoint, size);
        final zoomedOffset = zoomedPoint - zoomedAnchor;

        expect(zoomedOffset.dx, closeTo(baseOffset.dx * zoom, 0.0001));
        expect(zoomedOffset.dy, closeTo(baseOffset.dy * zoom, 0.0001));
      }
    }
  });

  test('coverage width at tractor uses the working-width screen scale', () {
    const cases = [
      (size: Size(1200, 700), horizontalPerspective: 1.20),
      (size: Size(700, 1200), horizontalPerspective: 1.55),
    ];

    for (final testCase in cases) {
      final painter = createPainter(scale: 1, size: testCase.size);
      final left = painter.toScreen(
        const XYPoint(x: -workingWidth / 2, y: 0),
        testCase.size,
      );
      final right = painter.toScreen(
        const XYPoint(x: workingWidth / 2, y: 0),
        testCase.size,
      );
      final expectedWidth =
          workingWidth * 4.25 * testCase.horizontalPerspective;

      expect((right.dx - left.dx).abs(), closeTo(expectedWidth, 0.0001));
    }
  });

  test('course-up keeps a point on the heading above the tractor', () {
    const size = Size(1200, 700);
    final painter = createPainter(scale: 1, size: size, heading: 90);
    final anchor = painter.toScreen(currentPoint, size);
    final pointToEast = painter.toScreen(const XYPoint(x: 100, y: 0), size);

    expect(pointToEast.dx, closeTo(anchor.dx, 0.0001));
    expect(pointToEast.dy, lessThan(anchor.dy));
  });

  test('view offset moves only the projected navigation scene', () {
    const size = Size(1200, 700);
    const offset = Offset(86, -42);
    const worldPoint = XYPoint(x: 18, y: 70);
    final basePoint = createPainter(
      scale: 1,
      size: size,
    ).toScreen(worldPoint, size);
    final pannedPoint = createPainter(
      scale: 1,
      size: size,
      viewOffset: offset,
    ).toScreen(worldPoint, size);

    expect(pannedPoint, basePoint + offset);
  });

  testWidgets('tractor overlay follows the projected GPS point while panning', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: NavigationCanvas(
              firstPass: [],
              guidanceLines: [],
              coveragePolygons: [],
              currentPoint: currentPoint,
              workingWidth: workingWidth,
              gpsHeading: 0,
              rotateWithGpsHeading: true,
            ),
          ),
        ),
      ),
    );

    CustomPaint paintedScene() => tester.widget(find.byType(CustomPaint));

    final initialPaint = paintedScene();
    final initialOverlay =
        initialPaint.foregroundPainter! as TractorOverlayPainter;

    await tester.drag(find.byType(NavigationCanvas), const Offset(70, -35));
    await tester.pump();

    final pannedPaint = paintedScene();
    final pannedScene = pannedPaint.painter! as NavigationPainter;
    final pannedOverlay =
        pannedPaint.foregroundPainter! as TractorOverlayPainter;
    final canvasSize = tester.getSize(find.byType(CustomPaint));

    expect(pannedScene.viewOffset, isNot(Offset.zero));
    expect(
      pannedOverlay.tractorAnchor,
      pannedScene.toScreen(currentPoint, canvasSize),
    );
    expect(pannedOverlay.implementWidth, initialOverlay.implementWidth);

    await tester.tap(find.byType(NavigationCanvas));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(NavigationCanvas));
    await tester.pump(const Duration(milliseconds: 500));

    final resetPaint = paintedScene();
    final resetScene = resetPaint.painter! as NavigationPainter;
    final resetOverlay = resetPaint.foregroundPainter! as TractorOverlayPainter;

    expect(resetScene.viewOffset, Offset.zero);
    expect(resetScene.scale, 1.0);
    expect(resetOverlay.tractorAnchor, initialOverlay.tractorAnchor);
  });
}
