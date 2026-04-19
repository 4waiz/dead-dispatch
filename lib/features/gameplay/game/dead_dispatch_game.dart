import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/perf/perf_monitor.dart';
import '../../../domain/models/shift_config.dart';
import '../../../presentation/theme/colors.dart';

/// Phase 1 Flame shell. Boots the game view, paints a placeholder stage,
/// and exposes two callbacks the `GameScreen` wires up:
///
///   * [onRequestEnd]  — fires when the player taps the "End shift"
///                       placeholder button. Phase 2 will replace this
///                       with the real shift-timer flow.
///   * [onFirstFrame]  — fires once after the initial render so the
///                       HUD can start timers in sync with the engine.
///
/// Deliberately empty of gameplay systems — those stay in
/// `../game_legacy/` until Phase 2 wires them back in. That keeps this
/// file a small, obvious integration point.
class DeadDispatchGame extends FlameGame with TapCallbacks {
  DeadDispatchGame({
    required this.config,
    required this.perf,
    required this.onRequestEnd,
    required this.onFirstFrame,
  });

  final ShiftConfig config;
  final PerfMonitor perf;
  final VoidCallback onRequestEnd;
  final VoidCallback onFirstFrame;

  bool _firedFirstFrame = false;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_PlaceholderStage());
  }

  @override
  void update(double dt) {
    super.update(dt);
    perf.record(dt * 1000);
    if (!_firedFirstFrame) {
      _firedFirstFrame = true;
      onFirstFrame();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onRequestEnd();
}

/// Placeholder visual so the shell isn't just a black screen during
/// Phase 1. Two horizontal bands evoke the real belt layout without
/// committing to final geometry.
class _PlaceholderStage extends Component with HasGameReference {
  @override
  void render(Canvas canvas) {
    final size = game.size;
    final stripe = Paint()..color = AppColors.surfaceHi;
    final band = Paint()..color = AppColors.accentBelt;
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.48, size.x, 40),
      band,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.72, size.x, 40),
      band,
    );
    for (double x = 0; x < size.x; x += 24) {
      canvas.drawRect(
        Rect.fromLTWH(x, size.y * 0.48 + 6, 12, 28),
        stripe,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 12, size.y * 0.72 + 6, 12, 28),
        stripe,
      );
    }
  }
}
