import 'package:agronavigator_app/models/xy_point.dart';
import 'package:agronavigator_app/models/vector2.dart';
// Строит полигон обработанной площади по GPS-треку трактора
class CoverageGenerator {
  final List<XYPoint> track = [];

  void addPoint(XYPoint point) { // Добавляет новую точку трека
    track.add(point);
  }

  void clear() { // Очищает текущий трек
    track.clear();
  }

// Генерирует полигон обработанной площади
// За основу берется трек движения, который смещается
// на половину рабочей ширины влево и вправо

  List<XYPoint> generatePolygon(double workingWidth) {
  if (track.length < 2) { // Для построения полигона нужны как минимум 2 точки
    return [];
  }

  final left = <XYPoint>[];
  final right = <XYPoint>[];

  final halfWidth = workingWidth / 2; // Половина рабочей ширины относительно центра трактора

  for (int i = 0; i < track.length - 1; i++) { // Проходим по всем участкам трека
    final start = track[i];
    final end = track[i + 1];

    final direction = Vector2.fromPoints(start, end);

    if (direction.length == 0) { // Если трактор не сместился, построить перпендикулярный вектор невозможно
      continue;
    }
    // Получаем вектор, перпендикулярный направлению движения,
    // и масштабируем его до половины рабочей ширины
    final shift = direction.perpendicular * halfWidth;
    // Добавляем левые и правые границы обработанной полосы
    left.add(start + shift);
    right.add(start + (shift * -1));
    // Для последнего участка также добавляем конечную точку,
    // чтобы полигон был полностью замкнут
    if (i == track.length - 2) {
      left.add(end + shift);
      right.add(end + (shift * -1));
    }
  }

  return [ // Объединяем левую и правую границу в один замкнутый полигон
    ...left,
    ...right.reversed,
  ];

  }
}