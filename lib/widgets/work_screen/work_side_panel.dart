import 'package:flutter/material.dart';

class WorkSidePanel extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final VoidCallback? onYield;
  final bool isPaused;
  final bool hasStarted;
  final bool controlsEnabled;
  final bool compact;

  const WorkSidePanel({
    super.key,
    required this.onStart,
    required this.onPauseResume,
    required this.onStop,
    this.onYield,
    required this.isPaused,
    required this.hasStarted,
    this.controlsEnabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBE6CF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332A7338),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SideButton(
            label: 'Старт',
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF38A852),
            onPressed: !hasStarted && controlsEnabled ? onStart : null,
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SideButton(
            label: isPaused ? 'Продолжить' : 'Пауза',
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: const Color(0xFFF2AC16),
            onPressed: hasStarted && controlsEnabled ? onPauseResume : null,
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SideButton(
            label: 'Стоп',
            icon: Icons.stop_rounded,
            color: const Color(0xFFE64A4A),
            onPressed: hasStarted && controlsEnabled ? onStop : null,
            compact: compact,
          ),
          if (onYield != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
              child: SizedBox(
                width: compact ? 38 : 42,
                child: const Divider(height: 1),
              ),
            ),
            _SideButton(
              label: 'Урожай',
              icon: Icons.agriculture_rounded,
              color: const Color(0xFF82A914),
              onPressed: onYield,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool compact;

  const _SideButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final backgroundColor = enabled
        ? color
        : Color.alphaBlend(
            color.withValues(alpha: 0.14),
            const Color(0xFFF7FAF7),
          );
    final foregroundColor = enabled
        ? Colors.white
        : color.withValues(alpha: 0.48);

    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(13),
            splashColor: Colors.white.withValues(alpha: 0.24),
            child: SizedBox(
              width: compact ? 48 : 54,
              height: compact ? 46 : 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: compact ? 20 : 24, color: foregroundColor),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 8 : 9,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
