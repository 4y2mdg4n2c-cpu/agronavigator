import 'package:flutter/material.dart';
import 'package:agronavigator_app/widgets/info_card.dart';

class InfoBar extends StatelessWidget {
  final double area;
  final double speed;
  final double gpsAccuracy;
  final double? yieldValue;
  final double distance;
  final bool compact;

  const InfoBar({
    super.key,
    required this.area,
    required this.speed,
    required this.gpsAccuracy,
    this.yieldValue,
    required this.distance,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      InfoCard(
        icon: Icons.crop,
        title: 'Площадь',
        value: area.toStringAsFixed(2),
        unit: 'га',
        compact: compact,
      ),
      if (yieldValue != null)
        InfoCard(
          icon: Icons.agriculture,
          title: 'Урожайность',
          value: yieldValue!.toStringAsFixed(1),
          unit: 'ц/га',
          compact: compact,
        ),
      InfoCard(
        icon: Icons.straighten,
        title: 'Дистанция',
        value: distance.toStringAsFixed(0),
        unit: 'м',
        compact: compact,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(height: 6),
                    cards[index],
                  ],
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    cards[index],
                  ],
                ],
              ),
      ),
    );
  }
}
