import 'package:flutter/material.dart';
/// Виджет с кнопками управления рабочим процессом.
/// Отображает две плавающие кнопки:
/// - ▶ Начать проход;
/// - ■ Завершить проход.
/// Сам виджет не содержит логики работы.
/// При нажатии вызывает переданные функции:
/// [onStart] — запуск записи прохода;
/// [onStop] — завершение записи прохода.
class WorkControls extends StatelessWidget {
  final VoidCallback onStart; // Вызывается при нажатии кнопки "Старт"
  final VoidCallback onStop; // Вызывается при нажатии кнопки "Стоп"
/// Создает панель управления проходом.
/// Требует две функции:
/// [onStart] и [onStop].
// Вызывается при заполнении полного бункера.
  final VoidCallback onBunker;
  const WorkControls({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.onBunker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'start',
          mini: true,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          onPressed: onStart,
          child: const Icon(Icons.play_arrow),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'stop',
          mini: true,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          onPressed: onStop,
          child: const Icon(Icons.stop),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'bunker',
          mini: true,
          backgroundColor: Colors.yellow.withValues(alpha: 0.8),
          onPressed: onBunker,
          child: const Icon(Icons.agriculture),
        ),
      ],
    );
  }
}