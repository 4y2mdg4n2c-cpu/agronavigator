import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final bool compact;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 7 : 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 22 : 32, color: Colors.green),
            SizedBox(width: compact ? 7 : 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 11 : 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: compact ? 1 : 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: compact ? 16 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: compact ? 2 : 4),
                    Text(unit, style: TextStyle(fontSize: compact ? 11 : 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
