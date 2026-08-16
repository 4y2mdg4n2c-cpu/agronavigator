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
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      tooltip: 'Статистика работы',
      icon: Icon(isPanelVisible ? Icons.close : Icons.bar_chart, size: 20),
      onPressed: onPressed,
    );
  }
}
