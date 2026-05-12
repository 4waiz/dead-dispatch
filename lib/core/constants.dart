/// App-wide constants that aren't balancing data.
/// Anything tunable for game-feel goes in `assets/config/balance.json`.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Dead Dispatch';

  /// Min Android SDK we target (matches AndroidManifest minSdkVersion).
  static const int minAndroidSdk = 23;

  /// Storage keys.
  static const String kSaveFile = 'dd.save.v1';
  static const String kSettings = 'dd.settings.v1';
  static const String kProgression = 'dd.progression.v1';
  static const String kDaily = 'dd.daily.v1';
  static const String kSchemaVersion = 'dd.schema.version';

  /// Current persistence schema. Bump + add a migration when shape changes.
  static const int saveSchemaVersion = 2;

  /// Target frame budget on mid/low-end Android (~16.6ms).
  static const Duration targetFrameBudget = Duration(microseconds: 16666);
}
