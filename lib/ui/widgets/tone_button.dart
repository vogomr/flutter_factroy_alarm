import 'package:flutter/material.dart';

class ToneButton extends StatelessWidget {
  final String label;
  final String file;
  final Color? color;
  final IconData? icon;
  final void Function(String file) onTap;

  const ToneButton({super.key, required this.label, required this.file, required this.onTap, this.color, this.icon});

  factory ToneButton.emergency({required String label, required String file, required void Function(String file) onTap, IconData? icon}) {
    return ToneButton(label: label, file: file, onTap: onTap, color: const Color(0xFFB00020), icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play $label',
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
        onPressed: () => onTap(file),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 32),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label.toUpperCase(), textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
