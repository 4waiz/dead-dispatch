import 'package:flutter/services.dart';

import '../core/logger.dart';

/// Haptic intent. Maps onto platform primitives — we don't expose ms
/// durations directly so balancing stays game-design-driven.
enum HapticIntent {
  uiTap,
  selection,
  success,
  failure,
  warning,
  heavyImpact;
}

abstract class HapticsService {
  bool get isEnabled;
  set isEnabled(bool value);
  Future<void> trigger(HapticIntent intent);
}

/// Default impl built on Flutter's [HapticFeedback]. Falls back to a noop
/// on platforms (web, desktop) that don't support it.
class FlutterHapticsService implements HapticsService {
  FlutterHapticsService({bool enabled = true}) : _enabled = enabled;

  bool _enabled;
  final AppLogger _log = AppLogger('Haptics');

  @override
  bool get isEnabled => _enabled;
  @override
  set isEnabled(bool value) => _enabled = value;

  @override
  Future<void> trigger(HapticIntent intent) async {
    if (!_enabled) return;
    try {
      switch (intent) {
        case HapticIntent.uiTap:
          await HapticFeedback.selectionClick();
        case HapticIntent.selection:
          await HapticFeedback.selectionClick();
        case HapticIntent.success:
          await HapticFeedback.lightImpact();
        case HapticIntent.failure:
          await HapticFeedback.heavyImpact();
        case HapticIntent.warning:
          await HapticFeedback.mediumImpact();
        case HapticIntent.heavyImpact:
          await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _log.w('Haptic failed: $e');
    }
  }
}
