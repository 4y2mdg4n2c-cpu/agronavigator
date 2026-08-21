import 'package:flutter/material.dart';

class WorkStatisticsPanel extends StatelessWidget {
  final String fieldName;
  final double sessionArea;
  final double totalFieldArea;
  final double sessionDistance;
  final double workingWidth;
  final double? yieldValue;
  final VoidCallback onClose;

  const WorkStatisticsPanel({
    super.key,
    required this.fieldName,
    required this.sessionArea,
    required this.totalFieldArea,
    required this.sessionDistance,
    required this.workingWidth,
    this.yieldValue,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: const Color(0x5530733C),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFC8E5CD), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF5E3),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 20,
                      color: Color(0xFF347C43),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fieldName,
                      style: const TextStyle(
                        color: Color(0xFF18361F),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
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
              const Divider(height: 20, color: Color(0xFFDCEADF)),
              _StatLine(
                label: 'Текущая сессия',
                value: '${sessionArea.toStringAsFixed(2)} га',
              ),
              _StatLine(
                label: 'Общая площадь поля',
                value: '${totalFieldArea.toStringAsFixed(2)} га',
              ),
              _StatLine(
                label: 'Расстояние сессии',
                value: '${(sessionDistance / 1000).toStringAsFixed(2)} км',
              ),
              _StatLine(
                label: 'Рабочая ширина',
                value: '${workingWidth.toStringAsFixed(2)} м',
              ),
              if (yieldValue != null)
                _StatLine(
                  label: 'Урожайность',
                  value: '${yieldValue!.toStringAsFixed(2)} ц/га',
                  accent: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _StatLine({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7D887F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: accent ? const Color(0xFF82A914) : const Color(0xFF18361F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
