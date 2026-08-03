import '../models/xy_point.dart';
// Вычислить площадь полигона в гектарах
class HectareCalculator {
  double calculate(List<XYPoint> polygon) {
    // Для вычисления площади нужно минимум 3 точки
    if (polygon.length < 3) {
      return 0;
    }
    double area = 0;
    // Формула Гаусса
    // Последовательно обходим все вершины полигона,
    // включая переход от последней точки к первой
    for (int i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final nextIndex = (i + 1) % polygon.length;
      final next = polygon[nextIndex];
      area += current.x * next.y - current.y * next.x;
    }
    // Формула возвращает удвоенную ориентированную площадь
    // Берем модуль, делим на 2 и переводим квадратные метрвы в гектары
    return area.abs() / 2 / 10000;
  }
}