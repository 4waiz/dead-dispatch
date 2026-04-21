import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'belt_component.dart';
import 'package_component.dart';

/// Draws the office backdrop: ceiling lamp strips above each belt,
/// a faint grid floor, and a glowing gate zone marker.
class BackgroundComponent extends PositionComponent {
  BackgroundComponent() : super(priority: -1);

  static const _gridColor = Color(0x0DFFFFFF);
  static const _lampColor = Color(0x33F5C04A);
  static const _gateColor = Color(0x44F5C04A);

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Faint vertical grid lines
    final gridPaint = Paint()..color = _gridColor;
    for (double x = 0; x < w; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Ceiling lamp strips above each belt
    for (int i = 0; i < 2; i++) {
      final beltY = BeltComponent.centerY(i, h);
      final lampRect = Rect.fromLTWH(0, beltY - BeltComponent.beltHeight - 28, w, 10);
      canvas.drawRect(lampRect, Paint()..color = _lampColor);
      // Glow gradient below lamp
      final glowRect = Rect.fromLTWH(0, beltY - BeltComponent.beltHeight - 18, w, 40);
      canvas.drawRect(
        glowRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22F5C04A), Color(0x00F5C04A)],
          ).createShader(glowRect),
      );
    }

    // Gate zone: glowing vertical stripe at 72% width
    final gateX = PackageComponent.gateX(w);
    final gateRect = Rect.fromLTWH(gateX - 2, 0, 4, h);
    canvas.drawRect(gateRect, Paint()..color = _gateColor);

    // Soft halo around the gate line
    final haloRect = Rect.fromLTWH(gateX - 24, 0, 48, h);
    canvas.drawRect(
      haloRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00F5C04A), Color(0x18F5C04A), Color(0x00F5C04A)],
        ).createShader(haloRect),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
