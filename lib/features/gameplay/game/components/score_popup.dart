import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../domain/models/package.dart';
import '../../../../presentation/theme/colors.dart';

/// Floating "+50 PERFECT!" text that rises and fades after a sort outcome.
class ScorePopup extends PositionComponent {
  ScorePopup({
    required Vector2 center,
    required SortOutcome outcome,
    required int points,
  })  : _outcome = outcome,
        _points = points,
        super(position: center, anchor: Anchor.center, priority: 10);

  final SortOutcome _outcome;
  final int _points;
  double _elapsed = 0;
  static const double _duration = 1.1;

  String get _label {
    final sign = _points > 0 ? '+$_points' : '$_points';
    switch (_outcome) {
      case SortOutcome.perfect:
        return '$sign  PERFECT!';
      case SortOutcome.acceptable:
        return '$sign  OK';
      case SortOutcome.miss:
        return 'MISS';
      case SortOutcome.destroyed:
        return 'DESTROYED';
    }
  }

  ui.Color get _color {
    switch (_outcome) {
      case SortOutcome.perfect:
        return AppColors.accentGold;
      case SortOutcome.acceptable:
        return AppColors.accentOk;
      case SortOutcome.miss:
        return AppColors.accentDanger;
      case SortOutcome.destroyed:
        return const ui.Color(0xFF8888AA);
    }
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    position.y -= 55 * dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = t < 0.6 ? 1.0 : 1.0 - ((t - 0.6) / 0.4);
    final scale = t < 0.1 ? (t / 0.1) * 1.2 : (t < 0.2 ? 1.2 - (t - 0.1) / 0.1 * 0.2 : 1.0);

    canvas.save();
    canvas.scale(scale, scale);

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 18,
        fontWeight: ui.FontWeight.w800,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: _color.withValues(alpha: alpha),
        shadows: [
          ui.Shadow(
            color: const ui.Color(0xFF000000).withValues(alpha: alpha * 0.8),
            offset: const Offset(1, 2),
            blurRadius: 3,
          ),
        ],
      ),
    )
      ..addText(_label);

    final para = builder.build()..layout(const ui.ParagraphConstraints(width: 160));
    canvas.drawParagraph(para, const Offset(-80, -12));
    canvas.restore();
  }
}
