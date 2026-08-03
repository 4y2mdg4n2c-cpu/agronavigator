import 'package:flutter/material.dart';

class GpsDebugPanel extends StatelessWidget {
  final double accuracy;
  final double speed;
  final double heading;

  const GpsDebugPanel({
    super.key,
    required this.accuracy,
    required this.speed,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    final bool gpsOk = accuracy <= 20;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gpsOk ? '🛰 GPS: OK' : '🛰 GPS: Плохой сигнал',
              style: TextStyle(
                color: gpsOk ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('Точность: ${accuracy.toStringAsFixed(1)} м'),
            Text('Скорость: ${speed.toStringAsFixed(1)} м/с'),
            Text(
              'Курс: ${heading < 0 ? '--' : '${heading.toStringAsFixed(0)}°'}',
            ),
          ],
        ),
      ),
    );
  }
}