import 'package:flutter/material.dart';

class WorkStatisticsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isPanelVisible;

  const WorkStatisticsButton({
    super.key,
    required this.onPressed,
    required this.isPanelVisible,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x4030733C),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IconButton.filled(
        visualDensity: VisualDensity.compact,
        tooltip: 'Статистика работы',
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF347C43),
          foregroundColor: Colors.white,
        ),
        icon: Icon(isPanelVisible ? Icons.close : Icons.bar_chart, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
