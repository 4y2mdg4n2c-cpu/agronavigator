import 'package:flutter/material.dart';

class WorkTopPanel extends StatelessWidget {
  final double area;
  final double speed;
  final double? yieldValue;
  final double distance;
  final bool compact;

  const WorkTopPanel({
    super.key,
    required this.area,
    required this.speed,
    this.yieldValue,
    required this.distance,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = <Widget>[
          _Metric(
            icon: Icons.crop,
            accent: const Color(0xFF35A853),
            accentBackground: const Color(0xFFDDF5E3),
            label: 'Площадь',
            value: area.toStringAsFixed(2),
            unit: 'га',
            compact: compact,
          ),
          _Metric(
            icon: Icons.speed,
            accent: const Color(0xFF168DA3),
            accentBackground: const Color(0xFFDDF3F6),
            label: 'Скорость',
            value: speed.toStringAsFixed(1),
            unit: 'км/ч',
            compact: compact,
          ),
          if (yieldValue != null)
            _Metric(
              icon: Icons.agriculture_outlined,
              accent: const Color(0xFFE09A16),
              accentBackground: const Color(0xFFFFEFCB),
              label: 'Урожайность',
              value: yieldValue!.toStringAsFixed(1),
              unit: 'ц/га',
              compact: compact,
            ),
          _Metric(
            icon: Icons.route_outlined,
            accent: const Color(0xFF6F65C8),
            accentBackground: const Color(0xFFE9E6FB),
            label: 'Дистанция',
            value: distance.toStringAsFixed(0),
            unit: 'м',
            compact: compact,
          ),
        ];

        final content = compact
            ? _CompactMetrics(items: items)
            : Row(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    Expanded(child: items[index]),
                    if (index < items.length - 1) const _MetricDivider(),
                  ],
                ],
              );

        return Container(
          constraints: const BoxConstraints(maxWidth: 760),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8,
            vertical: compact ? 4 : 7,
          ),
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
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _CompactMetrics extends StatelessWidget {
  final List<Widget> items;

  const _CompactMetrics({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < items.length; index += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: items[index]),
            if (index + 1 < items.length) ...[
              const _MetricDivider(),
              Expanded(child: items[index + 1]),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: Color(0xFFDDEBDF)),
          rows[index],
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool compact;
  final Color accent;
  final Color accentBackground;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.compact,
    required this.accent,
    required this.accentBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 7,
        vertical: compact ? 4 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 29 : 39,
            height: compact ? 29 : 39,
            decoration: BoxDecoration(
              color: accentBackground,
              borderRadius: BorderRadius.circular(compact ? 9 : 12),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: compact ? 17 : 22, color: accent),
          ),
          SizedBox(width: compact ? 5 : 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF78857B),
                    fontSize: compact ? 8.5 : 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: const Color(0xFF152D1A),
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        color: const Color(0xFF59675C),
                        fontSize: compact ? 9 : 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFFDDEBDF));
  }
}
