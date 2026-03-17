import 'package:flutter/material.dart';

class LcdDisplay extends StatelessWidget {
  final String text;
  final bool isActive;

  const LcdDisplay({super.key, required this.text, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1D2630), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '• System Monitor •',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.4,
              color: Colors.blue.shade200,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.greenAccent : Colors.white70,
              shadows: isActive
                  ? [const Shadow(color: Colors.greenAccent, blurRadius: 16, offset: Offset(0, 0))]
                  : [const Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))],
            ),
          ),
        ],
      ),
    );
  }
}