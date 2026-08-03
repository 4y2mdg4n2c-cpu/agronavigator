import 'package:flutter/material.dart';
import 'package:agronavigator_app/widgets/info_card.dart';
class InfoBar extends StatelessWidget {
  final double area;
  final double speed;
  final double gpsAccuracy;
  final double? yieldValue;
  final double distance;

  const InfoBar({
    super.key,
    required this.area,
    required this.speed,
    required this.gpsAccuracy,
    this.yieldValue,
    required this.distance,
  });

  @override
Widget build(BuildContext context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoCard(
            icon: Icons.crop,
            title: 'Площадь',
            value: area.toStringAsFixed(2),
            unit: 'га',
          ),
          const SizedBox(width: 8),
          if (yieldValue != null)
            InfoCard(
              icon: Icons.agriculture,
              title: 'Урожайность',
              value: yieldValue!.toStringAsFixed(1),
              unit: 'ц/га',
            ),
          const SizedBox(width: 8),
          InfoCard(
            icon: Icons.straighten,
            title: 'Дистанция',
            value: distance.toStringAsFixed(0),
            unit: 'м',
          ),
        ],
      ),
    ),
  );
 }
}