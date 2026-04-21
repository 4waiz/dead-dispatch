import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Short-lived burst of coloured rectangles to signal a routing outcome.
class ParticleBurst extends PositionComponent {
  ParticleBurst({required Vector2 center, required Color color, int count = 8})
      : _color = color,
        _parts = List.generate(count, (i) {
          final angle = i * math.pi * 2 / count;
          return _Pt(
            dx: math.cos(angle) * (48 + (i % 3) * 14),
            dy: math.sin(angle) * (48 + (i % 3) * 14),
          );
        }),
        super(position: center, priority: 20);

  final Color _color;
  final List<_Pt> _parts;
  double _elapsed = 0;
  static const double _duration = 0.45;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()..color = _color.withValues(alpha: alpha);
    for (final p in _parts) {
      final x = p.dx * progress;
      final y = p.dy * progress;
      canvas.drawRect(Rect.fromLTWH(x - 4, y - 4, 8, 8), paint);
    }
  }
}

class _Pt {
  const _Pt({required this.dx, required this.dy});
  final double dx;
  final double dy;
}
