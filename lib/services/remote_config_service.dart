import '../core/logger.dart';

/// Lightweight remote-config interface. The default impl returns
/// hardcoded defaults — perfect for offline-first launch. When Firebase
/// Remote Config (or LaunchDarkly etc.) is wired up later, swap the impl
/// in `di/providers.dart` without touching call sites.
abstract class RemoteConfigService {
  Future<void> initialize();
  bool getBool(String key, {bool defaultValue = false});
  int getInt(String key, {int defaultValue = 0});
  double getDouble(String key, {double defaultValue = 0});
  String getString(String key, {String defaultValue = ''});
  Future<void> refresh();
}

class StaticRemoteConfigService implements RemoteConfigService {
  StaticRemoteConfigService({Map<String, Object>? defaults})
      : _values = {...?defaults};

  final Map<String, Object> _values;
  final AppLogger _log = AppLogger('RemoteConfig');

  @override
  Future<void> initialize() async {
    _log.i('Static remote config: ${_values.length} keys.');
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _values[key] is bool ? _values[key]! as bool : defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      _values[key] is num ? (_values[key]! as num).toInt() : defaultValue;

  @override
  double getDouble(String key, {double defaultValue = 0}) =>
      _values[key] is num ? (_values[key]! as num).toDouble() : defaultValue;

  @override
  String getString(String key, {String defaultValue = ''}) =>
      _values[key] is String ? _values[key]! as String : defaultValue;

  @override
  Future<void> refresh() async {}
}
