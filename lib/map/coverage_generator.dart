import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/models/vector2.dart';

// Строит полигон обработанной площади по GPS-треку трактора
class CoverageGenerator {
  final List<List<XYPoint>> tracks = [[]];

  void addPoint(XYPoint point) {
    tracks.last.add(point);
  }

  void startNewSegment() {
    if (tracks.last.isNotEmpty) {
      tracks.add([]);
    }
  }

  void clear() {
    tracks
      ..clear()
      ..add([]);
  }

  void loadTracks(List<List<XYPoint>> savedTracks) {
    tracks
      ..clear()
      ..addAll(savedTracks);

    if (tracks.isEmpty) {
      tracks.add([]);
    }
  }

  List<List<XYPoint>> generatePolygons(double workingWidth) {
    return tracks
        .map((track) => _generatePolygon(track, workingWidth))
        .where((polygon) => polygon.isNotEmpty)
        .toList();
  }

  List<XYPoint> _generatePolygon(List<XYPoint> track, double workingWidth) {
    if (track.length < 2) {
      return [];
    }

    final left = <XYPoint>[];
    final right = <XYPoint>[];
    final halfWidth = workingWidth / 2;

    for (int i = 0; i < track.length - 1; i++) {
      final start = track[i];
      final end = track[i + 1];

      final direction = Vector2.fromPoints(start, end);

      if (direction.length == 0) {
        continue;
      }
      final shift = direction.perpendicular * halfWidth;
      left.add(start + shift);
      right.add(start + (shift * -1));
      if (i == track.length - 2) {
        left.add(end + shift);
        right.add(end + (shift * -1));
      }
    }

    return [...left, ...right.reversed];
  }
}
