/// Build-time environment & feature flags.
///
/// Resolved from `--dart-define` so debug/QA/release builds can flip
/// behavior without touching code.
library;

class Env {
  const Env._({
    required this.flavor,
    required this.enableAds,
    required this.enableAnalytics,
    required this.enableRemoteConfig,
    required this.debugTools,
  });

  final EnvFlavor flavor;
  final bool enableAds;
  final bool enableAnalytics;
  final bool enableRemoteConfig;
  final bool debugTools;

  bool get isRelease => flavor == EnvFlavor.release;
  bool get isDebug => flavor == EnvFlavor.debug;

  static Env fromCompileFlags() {
    const flavorName =
        String.fromEnvironment('FLAVOR', defaultValue: 'debug');
    const enableAds = bool.fromEnvironment('ENABLE_ADS', defaultValue: false);
    const enableAnalytics =
        bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
    const enableRemoteConfig =
        bool.fromEnvironment('ENABLE_REMOTE_CONFIG', defaultValue: false);
    const debugTools =
        bool.fromEnvironment('DEBUG_TOOLS', defaultValue: true);

    return Env._(
      flavor: EnvFlavor.parse(flavorName),
      enableAds: enableAds,
      enableAnalytics: enableAnalytics,
      enableRemoteConfig: enableRemoteConfig,
      debugTools: debugTools,
    );
  }
}

enum EnvFlavor {
  debug,
  qa,
  release;

  static EnvFlavor parse(String value) {
    switch (value) {
      case 'release':
        return EnvFlavor.release;
      case 'qa':
        return EnvFlavor.qa;
      default:
        return EnvFlavor.debug;
    }
  }
}
