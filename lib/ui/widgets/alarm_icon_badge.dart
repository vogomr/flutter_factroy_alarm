import 'package:flutter/material.dart';

class AlarmIconBadge extends StatelessWidget {
  final double size;
  final bool animated;

  const AlarmIconBadge({
    super.key,
    this.size = 100,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: _buildBadge(),
      );
    }
    return _buildBadge();
  }

  Widget _buildBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F4F8), Color(0xFFF5F5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4757).withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFFFF4757).withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _AlarmIconPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _AlarmIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 100;

    // === Draw sound waves (left) ===
    final waveLeftPaint = Paint()
      ..color = const Color(0xFFFF6B5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    // Wave 1 (outer)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX - 22 * scale, centerY - 8 * scale),
        width: 16 * scale,
        height: 16 * scale,
      ),
      -1.57,
      1.57,
      false,
      waveLeftPaint,
    );

    // Wave 2 (middle)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX - 22 * scale, centerY - 8 * scale),
        width: 28 * scale,
        height: 28 * scale,
      ),
      -1.57,
      1.57,
      false,
      waveLeftPaint,
    );

    // === Draw sound waves (right) ===
    // Wave 1 (outer)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX + 22 * scale, centerY - 8 * scale),
        width: 16 * scale,
        height: 16 * scale,
      ),
      -1.57,
      1.57,
      false,
      waveLeftPaint,
    );

    // Wave 2 (middle)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX + 22 * scale, centerY - 8 * scale),
        width: 28 * scale,
        height: 28 * scale,
      ),
      -1.57,
      1.57,
      false,
      waveLeftPaint,
    );

    // === Draw bell body ===
    final bellPaint = Paint()
      ..color = const Color(0xFFFF6B5B)
      ..style = PaintingStyle.fill;

    // Bell main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 2 * scale),
          width: 32 * scale,
          height: 28 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      bellPaint,
    );

    // Bell top curves
    canvas.drawPath(
      _createBellPath(centerX, centerY + 2 * scale, scale),
      bellPaint,
    );

    // === Draw bell clapper (small circle at bottom) ===
    canvas.drawCircle(
      Offset(centerX, centerY + 24 * scale),
      4 * scale,
      bellPaint,
    );

    // === Draw shield inside bell ===
    final shieldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final shieldStrokePaint = Paint()
      ..color = const Color(0xFFFF6B5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;

    // Shield shape
    final shieldPath = Path();
    shieldPath.moveTo(centerX - 10 * scale, centerY - 4 * scale);
    shieldPath.lineTo(centerX + 10 * scale, centerY - 4 * scale);
    shieldPath.lineTo(centerX + 10 * scale, centerY + 6 * scale);
    shieldPath.quadraticBezierTo(
      centerX,
      centerY + 14 * scale,
      centerX - 10 * scale,
      centerY + 6 * scale,
    );
    shieldPath.close();

    canvas.drawPath(shieldPath, shieldPaint);
    canvas.drawPath(shieldPath, shieldStrokePaint);

    // === Draw highlight for glossy effect ===
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - 20 * scale,
          centerY - 18 * scale,
          28 * scale,
          12 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      highlightPaint,
    );
  }

  Path _createBellPath(double cx, double cy, double scale) {
    final path = Path();
    path.moveTo(cx - 10 * scale, cy - 12 * scale);
    path.quadraticBezierTo(cx - 12 * scale, cy - 16 * scale, cx - 6 * scale, cy - 18 * scale);
    path.quadraticBezierTo(cx, cy - 19 * scale, cx + 6 * scale, cy - 18 * scale);
    path.quadraticBezierTo(cx + 12 * scale, cy - 16 * scale, cx + 10 * scale, cy - 12 * scale);
    return path;
  }

  @override
  bool shouldRepaint(_AlarmIconPainter oldDelegate) => false;
}
