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
  final bool compact;
  const WorkControls({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.onBunker,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          heroTag: 'start',
          compact: compact,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          onPressed: onStart,
          icon: Icons.play_arrow,
        ),
        SizedBox(height: compact ? 6 : 12),
        _ControlButton(
          heroTag: 'stop',
          compact: compact,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          onPressed: onStop,
          icon: Icons.stop,
        ),
        SizedBox(height: compact ? 6 : 12),
        _ControlButton(
          heroTag: 'bunker',
          compact: compact,
          backgroundColor: Colors.yellow.withValues(alpha: 0.8),
          onPressed: onBunker,
          icon: Icons.agriculture,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String heroTag;
  final bool compact;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final IconData icon;

  const _ControlButton({
    required this.heroTag,
    required this.compact,
    required this.backgroundColor,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      child: Icon(icon, size: compact ? 20 : 24),
    );

    if (!compact) {
      return button;
    }

    return SizedBox.square(dimension: 36, child: FittedBox(child: button));
  }
}
