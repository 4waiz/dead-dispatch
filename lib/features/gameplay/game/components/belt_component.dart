import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../presentation/theme/colors.dart';

/// Scrolling conveyor-belt backdrop. Two horizontal stripes at fixed
/// proportional positions.
class BeltComponent extends PositionComponent {
  BeltComponent() : super(priority: 0);

  static const int count = 2;
  static const double beltHeight = 56.0;
  static const double _slatW = 14.0;
  static const double _slatH = 42.0;
  static const double _scrollSpeed = 80.0;

  double _scrollOffset = 0;

  /// Top-y of belt [index] for the given game height.
  static double topY(int index, double gameHeight) =>
      index == 0 ? gameHeight * 0.48 : gameHeight * 0.72;

  /// Center-y of belt [index] for the given game height.
  static double centerY(int index, double gameHeight) =>
      topY(index, gameHeight) + beltHeight / 2;

  @override
  void update(double dt) {
    _scrollOffset = (_scrollOffset + _scrollSpeed * dt) % (_slatW * 2);
  }

  @override
  void render(Canvas canvas) {
    final gSize = size;
    if (gSize == Vector2.zero()) return;

    final bandPaint = Paint()..color = AppColors.accentBelt;
    final slatPaint = Paint()..color = AppColors.surfaceHi;

    for (var i = 0; i < count; i++) {
      final y = topY(i, gSize.y);
      canvas.drawRect(Rect.fromLTWH(0, y, gSize.x, beltHeight), bandPaint);

      var x = -_scrollOffset;
      while (x < gSize.x) {
        canvas.drawRect(
          Rect.fromLTWH(x, y + (beltHeight - _slatH) / 2, _slatW, _slatH),
          slatPaint,
        );
        x += _slatW * 2;
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
