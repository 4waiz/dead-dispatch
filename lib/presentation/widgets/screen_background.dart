import 'package:flutter/material.dart';

/// The shared diagonal-gold-stripes + bottom-glow backdrop used across
/// every full-page screen. Centralised so every screen — splash,
/// tutorial, menu, brief, gameplay, result, settings, upgrades,
/// departments, daily, debug — shares the same haunted-desk feel.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(child: _BackgroundPainter()),
    );
  }
}

class _BackgroundPainter extends StatelessWidget {
  const _BackgroundPainter();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _Painter());
}

class _Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x07F5C04A)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    final glowRect = Rect.fromLTWH(
      0,
      size.height * 0.6,
      size.width,
      size.height * 0.4,
    );
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x1AF5C04A), Color(0x00F5C04A)],
        ).createShader(glowRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
