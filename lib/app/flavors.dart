import '../core/env.dart';

/// Resolved runtime configuration per build flavor. Each flavor maps the
/// abstract `Env` into concrete switches — e.g. debug builds enable the
/// debug menu, release builds force ads on. This is the single file
/// where "what does this flavor mean?" is answered.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.showDebugMenu,
    required this.enableVerboseLogs,
    required this.enableCheats,
    required this.adsBehavior,
    required this.analyticsBehavior,
  });

  final EnvFlavor flavor;
  final bool showDebugMenu;
  final bool enableVerboseLogs;
  final bool enableCheats;
  final AdsBehavior adsBehavior;
  final AnalyticsBehavior analyticsBehavior;

  static FlavorConfig forEnv(Env env) {
    switch (env.flavor) {
      case EnvFlavor.debug:
        return FlavorConfig(
          flavor: env.flavor,
          showDebugMenu: true,
          enableVerboseLogs: true,
          enableCheats: true,
          adsBehavior: AdsBehavior.offlineReward,
          analyticsBehavior: AnalyticsBehavior.logOnly,
        );
      case EnvFlavor.qa:
        return FlavorConfig(
          flavor: env.flavor,
          showDebugMenu: true,
          enableVerboseLogs: true,
          enableCheats: true,
          adsBehavior: env.enableAds
              ? AdsBehavior.real
              : AdsBehavior.offlineReward,
          analyticsBehavior: env.enableAnalytics
              ? AnalyticsBehavior.real
              : AnalyticsBehavior.logOnly,
        );
      case EnvFlavor.release:
        return FlavorConfig(
          flavor: env.flavor,
          showDebugMenu: false,
          enableVerboseLogs: false,
          enableCheats: false,
          adsBehavior: env.enableAds
              ? AdsBehavior.real
              : AdsBehavior.offlineReward,
          analyticsBehavior: env.enableAnalytics
              ? AnalyticsBehavior.real
              : AnalyticsBehavior.logOnly,
        );
    }
  }
}

enum AdsBehavior { offlineReward, real, disabled }

enum AnalyticsBehavior { logOnly, real }
