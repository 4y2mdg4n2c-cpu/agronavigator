import 'package:flutter/material.dart';
enum GpsSignalLevel {
  noSignal,
  weak,
  medium,
  good,
  excellent,
}
GpsSignalLevel getGpsSignalLevel({
  required double accuracy,
  required bool hasSignal,
}) {
  if (!hasSignal || !accuracy.isFinite || accuracy <= 0) {
    return GpsSignalLevel.noSignal;
  }

  if (accuracy > 20) {
    return GpsSignalLevel.weak;
  }

  if (accuracy > 10) {
    return GpsSignalLevel.medium;
  }

  if (accuracy > 5) {
    return GpsSignalLevel.good;
  }

  return GpsSignalLevel.excellent;
}
class GpsSignalIndicator extends StatelessWidget {
  final double accuracy;
  final bool hasSignal;
  final double size;

  const GpsSignalIndicator({
    super.key,
    required this.accuracy,
    required this.hasSignal,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final level = getGpsSignalLevel(
      accuracy: accuracy,
      hasSignal: hasSignal,
    );

    final activeBars = _getActiveBars(level);
    final activeColor = _getActiveColor(level);
    final inactiveColor = Colors.grey.withValues(alpha: 0.45);

    return Semantics(
      label: _getDescription(level),
      child: SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final isActive = index < activeBars;

            return Container(
              width: size * 0.15,
              height: size * (0.25 + index * 0.18),
              margin: EdgeInsets.only(
                right: index == 3 ? 0 : size * 0.07,
              ),
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            );
          }),
        ),
      ),
    );
  }

  int _getActiveBars(GpsSignalLevel level) {
    switch (level) {
      case GpsSignalLevel.noSignal:
        return 0;
      case GpsSignalLevel.weak:
        return 1;
      case GpsSignalLevel.medium:
        return 2;
      case GpsSignalLevel.good:
        return 3;
      case GpsSignalLevel.excellent:
        return 4;
    }
  }

  Color _getActiveColor(GpsSignalLevel level) {
    switch (level) {
      case GpsSignalLevel.noSignal:
        return Colors.grey;
      case GpsSignalLevel.weak:
        return Colors.red;
      case GpsSignalLevel.medium:
        return Colors.orange;
      case GpsSignalLevel.good:
      case GpsSignalLevel.excellent:
        return Colors.green;
    }
  }

  String _getDescription(GpsSignalLevel level) {
    switch (level) {
      case GpsSignalLevel.noSignal:
        return 'GPS: нет сигнала';
      case GpsSignalLevel.weak:
        return 'GPS: слабый сигнал';
      case GpsSignalLevel.medium:
        return 'GPS: средний сигнал';
      case GpsSignalLevel.good:
        return 'GPS: хороший сигнал';
      case GpsSignalLevel.excellent:
        return 'GPS: отличный сигнал';
    }
  }
}