import 'package:flutter/material.dart';

class WorkStatisticsPanel extends StatelessWidget {
  final String fieldName;
  final double sessionArea;
  final double totalFieldArea;
  final double sessionDistance;
  final double workingWidth;
  final double yieldValue;
  final VoidCallback onClose;

  const WorkStatisticsPanel({
    super.key,
    required this.fieldName,
    required this.sessionArea,
    required this.totalFieldArea,
    required this.sessionDistance,
    required this.workingWidth,
    required this.yieldValue,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fieldName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Закрыть',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Divider(),
              Text('Текущая сессия: ${sessionArea.toStringAsFixed(2)} га'),
              Text(
                'Общая площадь поля: ${totalFieldArea.toStringAsFixed(2)} га',
              ),
              Text(
                'Расстояние сессии: '
                '${(sessionDistance / 1000).toStringAsFixed(2)} км',
              ),
              Text('Рабочая ширина: ${workingWidth.toStringAsFixed(2)} м'),
              Text('Урожайность: ${yieldValue.toStringAsFixed(2)} ц/га'),
            ],
          ),
        ),
      ),
    );
  }
}
