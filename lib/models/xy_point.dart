import 'package:agronavigator_app/models/vector2.dart';
// Точка в локальной системе координат
// Используется для всех геометрических вычислений
// (смещение проходов, расстояния, углы, площади)
class XYPoint {
  final double x; // x-координата в метрах
  final double y; // y-координата в метрах

  const XYPoint({ // создает точку с координатами x и y
    required this.x,
    required this.y,
  });

  XYPoint operator +(Vector2 other) {
    return XYPoint(
      x: x + other.dx,
      y: y + other.dy,
      );
  }
}