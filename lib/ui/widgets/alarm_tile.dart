import 'package:flutter/material.dart';

class AlarmTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final Future<void> Function() onTap;

  const AlarmTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? color.withValues(alpha: 0.08) : Colors.white;
    final borderSide = isActive ? BorderSide(color: color.withValues(alpha: 0.7), width: 2) : BorderSide.none;

    return Card(
      elevation: isActive ? 10 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: borderSide),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            try {
              await onTap();
            } catch (e) {
              messenger?.showSnackBar(
                SnackBar(
                  content: Text('Action failed: $e'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isActive ? color.darken(0.2) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

