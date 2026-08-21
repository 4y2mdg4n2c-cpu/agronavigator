import 'package:agronavigator_app/widgets/gps_signal_indicator.dart';
import 'package:flutter/material.dart';

class WorkBottomPanel extends StatelessWidget {
  final double accuracy;
  final bool hasSignal;
  final bool compact;

  const WorkBottomPanel({
    super.key,
    required this.accuracy,
    required this.hasSignal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E5CD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332A7338),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 30 : 36,
            height: compact ? 30 : 36,
            padding: EdgeInsets.all(compact ? 5 : 6),
            decoration: BoxDecoration(
              color: hasSignal
                  ? const Color(0xFFDDF5E3)
                  : const Color(0xFFF1F3F1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: GpsSignalIndicator(
              accuracy: accuracy,
              hasSignal: hasSignal,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(width: compact ? 7 : 9),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSignal ? 'GPS подключён' : 'Нет GPS-сигнала',
                style: TextStyle(
                  color: const Color(0xFF18361F),
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                hasSignal
                    ? 'Точность: ${accuracy.toStringAsFixed(1)} м'
                    : 'Точность недоступна',
                style: TextStyle(
                  color: const Color(0xFF7D887F),
                  fontSize: compact ? 8.5 : 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
