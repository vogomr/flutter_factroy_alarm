import 'package:flutter/material.dart';

class ToneButton extends StatelessWidget {
  final String label;
  final String file;
  final Color? color;
  final void Function(String file) onTap;

  const ToneButton({super.key, required this.label, required this.file, required this.onTap, this.color});

  factory ToneButton.emergency({required String label, required String file, required void Function(String file) onTap}) {
    return ToneButton(label: label, file: file, onTap: onTap, color: const Color(0xFFB00020));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play $label',
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
        onPressed: () => onTap(file),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label.toUpperCase(), textAlign: TextAlign.center)),
      ),
    );
  }
}
