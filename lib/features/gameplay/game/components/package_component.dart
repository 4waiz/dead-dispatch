import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../domain/models/hazard.dart';
import '../../../../domain/models/package.dart';
import '../../../../domain/models/package_type.dart';
import '../../../../presentation/theme/colors.dart';
import '../dead_dispatch_game.dart';
import 'belt_component.dart';

enum PackageStatus { moving, waiting, exiting }

/// Visual representation of one [GamePackage] on the belt.
class PackageComponent extends PositionComponent
    with HasGameReference<DeadDispatchGame> {
  PackageComponent({
    required this.pkg,
    required this.beltIndex,
    required double beltSpeedMultiplier,
  })  : _speedPx = _baseSpeedFor(pkg.type) * beltSpeedMultiplier,
        super(size: Vector2(52, 52), priority: 2, anchor: Anchor.center);

  final GamePackage pkg;
  final int beltIndex;

  final double _speedPx;
  PackageStatus status = PackageStatus.moving;
  double _waitPulse = 0;

  static double gateX(double gameWidth) => gameWidth * 0.72;

  static double _baseSpeedFor(PackageType type) {
    switch (type) {
      case PackageType.standard:   return 90;
      case PackageType.priority:   return 95;
      case PackageType.fragile:    return 70;
      case PackageType.frozen:     return 60;
      case PackageType.ghost:      return 110;
      case PackageType.mislabeled: return 95;
      case PackageType.duplicate:  return 95;
      case PackageType.decaying:   return 100;
    }
  }

  static String _iconFor(PackageType type) {
    switch (type) {
      case PackageType.standard:   return '📦';
      case PackageType.priority:   return '⚡';
      case PackageType.fragile:    return '🔮';
      case PackageType.frozen:     return '❄️';
      case PackageType.ghost:      return '👻';
      case PackageType.mislabeled: return '❓';
      case PackageType.duplicate:  return '✂️';
      case PackageType.decaying:   return '☠️';
    }
  }

  @override
  void onMount() {
    super.onMount();
    position = Vector2(
      -size.x,
      BeltComponent.centerY(beltIndex, game.size.y),
    );
  }

  @override
  void update(double dt) {
    switch (status) {
      case PackageStatus.moving:
        final jammed =
            game.session.state.activeHazards.contains(HazardKind.beltJam);
        if (!jammed) position.x += _speedPx * dt;
        if (position.x >= gateX(game.size.x)) {
          position.x = gateX(game.size.x);
          status = PackageStatus.waiting;
        }
        if (pkg.type == PackageType.frozen || pkg.type == PackageType.decaying) {
          pkg.decayProgress = (pkg.decayProgress + dt / 20.0).clamp(0.0, 1.0);
        }

      case PackageStatus.waiting:
        _waitPulse = (_waitPulse + dt * 3.0) % (2 * 3.14159);

      case PackageStatus.exiting:
        position.x += _speedPx * 2.5 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final col = AppColors.forPackage(pkg.type);
    final alpha = pkg.type == PackageType.ghost ? 0.6 : 1.0;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(2, 3)),
      Paint()..color = const ui.Color(0x55000000),
    );

    // Body
    canvas.drawRRect(rrect, Paint()..color = col.withValues(alpha: alpha));

    // Subtle top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 2, size.x - 8, size.y * 0.35),
        const Radius.circular(8),
      ),
      Paint()..color = const ui.Color(0x22FFFFFF),
    );

    // Decay warning tint
    if (pkg.decayProgress > 0.5) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.accentDanger
              .withValues(alpha: (pkg.decayProgress - 0.5) * 0.7),
      );
    }

    // Waiting pulse ring
    if (status == PackageStatus.waiting) {
      final pulseAlpha = (0.4 + 0.4 * _sinApprox(_waitPulse)).clamp(0.0, 1.0);
      canvas.drawRRect(
        rrect.inflate(3),
        Paint()
          ..color = AppColors.accentGold.withValues(alpha: pulseAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Stamp ring
    if (pkg.stamped) {
      canvas.drawRRect(
        rrect.deflate(2),
        Paint()
          ..color = AppColors.accentGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Emoji icon centred
    _drawEmoji(canvas, _iconFor(pkg.type), size.x / 2, size.y / 2);
  }

  void _drawEmoji(Canvas canvas, String emoji, double cx, double cy) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 22, textAlign: TextAlign.center),
    )..addText(emoji);
    final para = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 52));
    canvas.drawParagraph(para, Offset(cx - 26, cy - 14));
  }

  double _sinApprox(double x) {
    // Good-enough sine without dart:math import in a hot path
    final v = x % (2 * 3.14159);
    return v < 3.14159 ? (4 * v * (3.14159 - v)) / (3.14159 * 3.14159) - 1 + 1
        : -(4 * (v - 3.14159) * (2 * 3.14159 - (v - 3.14159))) /
                (3.14159 * 3.14159) +
            1 - 1;
  }
}
