import 'package:flutter/foundation.dart';

/// Compile-time debug guards. `kDebugMode` is constant-folded out of release
/// builds, so any code behind these flags incurs zero runtime cost in prod.
class DebugFlags {
  const DebugFlags._();

  /// Master switch for cheats / dev menu.
  static bool get cheatsEnabled => kDebugMode;

  /// Show FPS / frame budget overlay.
  static bool get showPerfOverlay => kDebugMode;

  /// Skip onboarding when launching directly into a level.
  static bool get skipTutorial = false;

  /// Force a specific daily-challenge seed (for QA).
  static int? forcedDailySeed;
}
