import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class GpsPositionFilter {
  Position? lastAcceptedPosition;

  /// Максимальная допустимая погрешность GPS в метрах.
  static const double maxAccuracy = 20;

  /// Минимальный запас допустимой скорости.
  ///
  /// Нужен, чтобы фильтр не блокировал медленное движение комбайна,
  /// даже если GPS показывает скорость неточно.
  static const double minimumAllowedSpeed = 4;

  /// Абсолютный предел скорости для дорожных испытаний.
  /// 55 м/с — примерно 198 км/ч.
  static const double maximumAllowedSpeed = 55;

  /// Дополнительный запас к скорости, которую сообщает GPS.
  static const double speedMargin = 4;

  Position? filter(Position newPosition) {
    // Точки с погрешностью хуже 20 метров не принимаем.
    if (!newPosition.accuracy.isFinite ||
        newPosition.accuracy <= 0 ||
        newPosition.accuracy > maxAccuracy) {
      return null;
    }

    // Первая хорошая точка: сравнивать её пока не с чем.
    if (lastAcceptedPosition == null) {
      lastAcceptedPosition = newPosition;
      return newPosition;
    }

    final previousPosition = lastAcceptedPosition!;

    final distance = Geolocator.distanceBetween(
      previousPosition.latitude,
      previousPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    final elapsedMilliseconds = newPosition.timestamp
        .difference(previousPosition.timestamp)
        .inMilliseconds;

    // Некорректное или повторяющееся время — точку не используем.
    if (elapsedMilliseconds <= 0) {
      return null;
    }

    final elapsedSeconds = elapsedMilliseconds / 1000;

    // Скорость, которая получилась по расстоянию между координатами.
    final calculatedSpeed = distance / elapsedSeconds;

    // Скорость GPS иногда сама ошибается, поэтому:
    // 1. добавляем запас;
    // 2. не опускаемся ниже 4 м/с;
    // 3. не разрешаем больше 55 м/с.
    final allowedSpeed = math.min(
      maximumAllowedSpeed,
      math.max(minimumAllowedSpeed, newPosition.speed + speedMargin),
    );

    // Если между двумя обновлениями получилась физически
    // неправдоподобная скорость, считаем новую точку скачком GPS.
    if (calculatedSpeed > allowedSpeed) {
      return null;
    }

    final smoothingFactor = _getSmoothingFactor(newPosition.speed);

    final filteredLatitude =
        previousPosition.latitude +
        (newPosition.latitude - previousPosition.latitude) * smoothingFactor;

    final filteredLongitude =
        previousPosition.longitude +
        (newPosition.longitude - previousPosition.longitude) * smoothingFactor;

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

    lastAcceptedPosition = filteredPosition;
    return filteredPosition;
  }

  /// На малой скорости сильнее сглаживаем гуляние GPS.
  /// На большой скорости меньше сглаживаем, чтобы карта не отставала.
  double _getSmoothingFactor(double speed) {
    if (speed < 1) {
      return 0.20;
    }

    if (speed < 3) {
      return 0.35;
    }

    if (speed < 10) {
      return 0.55;
    }

    return 0.75;
  }

  /// Очищает память фильтра перед новой работой.
  void reset() {
    lastAcceptedPosition = null;
  }
}
