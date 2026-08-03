import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:agronavigator_app/models/xy_point.dart';

/// Переводит GPS-координаты (LatLng)
/// в локальную систему координат (X/Y в метрах).
///
/// Начальная GPS-точка считается точкой (0, 0).
class CoordinateConverter {
  static const double metersPerDegree = 111320;
  static XYPoint latLngToXY(
    LatLng point,
    LatLng origin,
  ) {
    // Разница широты в градусах
    // (от начальной точки)
    final deltaLat = point.latitude - origin.latitude;

    // Разница долготы в градусах
    // (от начальной точки)
    final deltaLon = point.longitude - origin.longitude;

    // Перевод градусов в метры
    // (1 градус = 111320 метров)
    final y = deltaLat * metersPerDegree;
    // Переводим разницу долготы из градусов в метры
    // Используем cos(), потому что длина 1 градуса долготы
    // уменьшается по мере удалений от экватора
    final x = deltaLon *
        cos(origin.latitude * pi / 180) *
        metersPerDegree;

    return XYPoint(
      x: x,
      y: y,
    );
  }
// Преобразует локальные координаты (в метрах)
// обратно в GPS-координаты (широта и долгота).
//
// point  - точка в локальной системе координат.
// origin - начало координат (первая GPS-точка).
  static LatLng xyToLatLng(
    XYPoint point,
    LatLng origin,
  ) => LatLng( // Восстанавливаем широту
    origin.latitude + point.y / metersPerDegree,
    // Восстанавливаем долготу
    // Делим на cos(latitude) потому что 1 градуса долготы
    // уменьшается по прибилижения к полюсам
    origin.longitude + point.x / metersPerDegree / cos(origin.latitude * pi / 180),
  );
}