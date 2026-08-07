import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class GpsPositionFilter {
  Position? lastAcceptedPosition;
  Position? lastFilteredPosition;

  /// Точки с большей погрешностью пока не используем.
  static const double maxAccuracy = 20;

  /// Минимально допустимая скорость с запасом.
  ///
  /// 3 м/с = 10,8 км/ч.
  /// Это не минимальная скорость техники, а предел,
  /// который позволяет медленному движению проходить фильтр.
  static const double minimumAllowedSpeed = 3;

  /// Запас к скорости, которую сообщает GPS.
  static const double speedMargin = 3;

  /// Максимальная скорость для дорожных испытаний.
  static const double maximumAllowedSpeed = 55;

  /// Небольшой запас расстояния из-за естественной погрешности GPS.
  static const double distanceMargin = 2;

  Position? filter(Position newPosition) {
    // 1. Проверяем качество новой точки.
    if (!newPosition.accuracy.isFinite ||
        newPosition.accuracy <= 0 ||
        newPosition.accuracy > maxAccuracy) {
      return null;
    }

    // 2. Первую хорошую точку принимаем сразу.
    if (lastAcceptedPosition == null) {
      lastAcceptedPosition = newPosition;
      lastFilteredPosition = newPosition;
      return newPosition;
    }

    final previousPosition = lastAcceptedPosition!;

    // 3. Считаем время между последней принятой
    // и новой GPS-точкой.
    final elapsedMilliseconds = newPosition.timestamp
        .difference(previousPosition.timestamp)
        .inMilliseconds;

    if (elapsedMilliseconds <= 0) {
      return null;
    }

    final elapsedSeconds = elapsedMilliseconds / 1000;

    // 4. Считаем реальное расстояние между координатами.
    final distance = Geolocator.distanceBetween(
      previousPosition.latitude,
      previousPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // 5. Берём большую скорость из двух GPS-точек.
    final reportedSpeed = math.max(
      previousPosition.speed,
      newPosition.speed,
    );

    // 6. Вычисляем допустимую скорость с запасом.
    final allowedSpeed = math.min(
      maximumAllowedSpeed,
      math.max(
        minimumAllowedSpeed,
        reportedSpeed + speedMargin,
      ),
    );

    // 7. Вычисляем, какое расстояние можно было пройти
    // за прошедшее время.
    final allowedDistance =
        allowedSpeed * elapsedSeconds + distanceMargin;

    // 8. Если координата улетела слишком далеко,
    // считаем её выбросом GPS.
    if (distance > allowedDistance) {
      return null;
    }

    // 9. Точка прошла проверку.
    // Запоминаем именно сырую принятую точку,
    // без сглаживания и искусственного отставания.
    final double smoothingFactor;
    if (newPosition.accuracy <= 5) {
      smoothingFactor = 0.85;
    } else if (newPosition.accuracy <= 10) {
      smoothingFactor = 0.65;
    } else {
      smoothingFactor = 0.45;
    }
    
    final filteredLatitude = 
        lastFilteredPosition!.latitude +
        (newPosition.latitude - lastFilteredPosition!.latitude) *
            smoothingFactor;
    final filteredLongitude = 
        lastFilteredPosition!.longitude +
        (newPosition.longitude - lastFilteredPosition!.longitude) *
            smoothingFactor;
    final filteredPosition = Position(
      latitude: filteredLatitude,
      longitude: filteredLongitude,
      timestamp: newPosition.timestamp,
      accuracy: newPosition.accuracy,
      altitude: newPosition.altitude,
      altitudeAccuracy: newPosition.altitudeAccuracy,
      heading: newPosition.heading,
      headingAccuracy: newPosition.headingAccuracy,
      speed: newPosition.speed,
      speedAccuracy: newPosition.speedAccuracy,
      floor: newPosition.floor,
      isMocked: newPosition.isMocked,
    );
    lastAcceptedPosition = newPosition;
    lastFilteredPosition = filteredPosition;

    return filteredPosition;
  }

  void reset() {
    lastAcceptedPosition = null;
    lastFilteredPosition = null;
  }
}