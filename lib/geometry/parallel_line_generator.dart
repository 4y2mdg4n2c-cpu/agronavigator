import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/models/vector2.dart';

class ParallelLineGenerator {
  // Создает параллельный проход,
  // смещенный от первого на заданное расстояние
  static List<XYPoint> generate(
    List<XYPoint> firstPass,
    double offset,
  ) {
    // Для построения линии нужны как минимум 2 точки
    if (firstPass.length < 2) {
      return <XYPoint>[];
    }
    // Начало и конец первого прохода
    final start = firstPass[0];
    final end = firstPass[firstPass.length - 1];

    final direction = Vector2.fromPoints(start, end); // Вектор направления первого прохода
    final shift = direction.perpendicular; // Единичный вектор перпендикулярный направлению
    final shiftOffset = shift * offset; // Смещение на рабочую ширину

    // Смещаем каждую точку первого прохода
    // и получаем параллельную прямую
    return firstPass.map((point) {
      final shiftedPoint = point + shiftOffset;
      return shiftedPoint;
    }).toList();
    
  }
}
  
