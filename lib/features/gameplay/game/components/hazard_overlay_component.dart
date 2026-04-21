import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../domain/models/hazard.dart';
import '../dead_dispatch_game.dart';

/// Full-screen overlay that visualises active hazards.
/// Drawn at a high priority so it sits above packages.
class HazardOverlayComponent extends PositionComponent
    with HasGameReference<DeadDispatchGame> {
  HazardOverlayComponent() : super(priority: 10);

  double _flickerTime = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    final hazards = game.session.state.activeHazards;
    if (hazards.contains(HazardKind.powerFlicker)) {
      _flickerTime += dt * 7;
    } else {
      _flickerTime = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final hazards = game.session.state.activeHazards;
    final fullRect = Rect.fromLTWH(0, 0, size.x, size.y);

    if (hazards.contains(HazardKind.blackout)) {
      canvas.drawRect(fullRect, Paint()..color = const Color(0xCC000000));
    }

    if (hazards.contains(HazardKind.beltJam)) {
      canvas.drawRect(fullRect, Paint()..color = const Color(0x33E3573B));
      canvas.drawRect(
        fullRect.deflate(3),
        Paint()
          ..color = const Color(0xAAE3573B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }

    if (hazards.contains(HazardKind.powerFlicker)) {
      final t = _flickerTime % 1.0;
      final flicker = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
      canvas.drawRect(
        fullRect,
        Paint()..color = Color.fromARGB((flicker * 160).round(), 0, 0, 0),
      );
    }

    if (hazards.contains(HazardKind.surgeRush)) {
      canvas.drawRect(fullRect, Paint()..color = const Color(0x1AF5C04A));
    }

    if (hazards.contains(HazardKind.misrouteChain)) {
      canvas.drawRect(fullRect, Paint()..color = const Color(0x229F8AC2));
    }
  }
}
