import 'dart:math';
import 'package:agronavigator_app/models/xy_point.dart';
// Вектор смещения между двумя точками.
// В отличие от XYPoint, не хранит положение на карте,
// а описывает направление и величину перемещения.

class Vector2 {
  final double dx;
  final double dy;
  const Vector2({
    required this.dx,
    required this.dy
  });

  Vector2.fromPoints( // Создает вектор по двум точкам
    XYPoint start,
    XYPoint end,
  ) : dx = end.x - start.x,
      dy = end.y - start.y;

  double get length => sqrt(dx * dx + dy * dy); // Длина вектора в метрах
  Vector2 get normalized {
    if (length == 0) {
      return const Vector2(dx: 0, dy: 0); // Возвращает единичный вектор с тем же направлением
    } 
    return Vector2(dx: dx / length,
     dy: dy / length);
    }
  Vector2 get perpendicular { // Поворачивает вектор на 90 градусов против часовой стрелки
    return Vector2(dx: -dy / length,
     dy: dx / length);
  }
  Vector2 operator *(double value) { // Масштабирует вектор (например, Vector2(1, 0) * 9 -> Vector2(9, 0))
    return Vector2(dx: dx * value,
     dy: dy * value);
  }
}