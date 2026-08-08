import 'package:flutter/material.dart';

class WorkActionButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final bool isPaused;
  final bool hasStarted;
  const WorkActionButtons({
    super.key,
    required this.onStart,
    required this.onPauseResume,
    required this.isPaused,
    required this.onStop,
    required this.hasStarted,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!hasStarted)
          ElevatedButton(onPressed: onStart, child: const Text('Старт')),

        if (hasStarted)
          ElevatedButton(
            onPressed: onPauseResume,
            child: Text(isPaused ? 'Продолжить' : 'Пауза'),
          ),

        if (hasStarted)
          ElevatedButton(onPressed: onStop, child: const Text('Стоп')),
      ],
    );
  }
}
