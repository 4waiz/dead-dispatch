import '../core/logger.dart';

/// Game-wide analytics surface. Concrete impl can be Firebase, Amplitude,
/// GameAnalytics — domain code only knows this interface.
///
/// Keep event names *stable* — they're queried in dashboards. Adding new
/// events is fine; renaming requires a deprecation cycle.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?> params = const {}});
  Future<void> setUserProperty(String key, Object? value);
}

/// Default offline-safe implementation. Forwards everything to the logger
/// so devs see funnel events in the console, but doesn't ship anything off
/// the device.
class LoggingAnalyticsService implements AnalyticsService {
  final AppLogger _log = AppLogger('Analytics');

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?> params = const {}}) async {
    _log.i('event=$name params=$params');
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    _log.i('user.$key=$value');
  }
}

/// Canonical event names. Resist creating ad-hoc strings at call sites.
class AnalyticsEvents {
  const AnalyticsEvents._();

  static const String appOpen = 'app_open';
  static const String tutorialStart = 'tutorial_start';
  static const String tutorialComplete = 'tutorial_complete';
  static const String shiftStart = 'shift_start';
  static const String shiftEnd = 'shift_end';
  static const String shiftFail = 'shift_fail';
  static const String shiftContinue = 'shift_continue';
  static const String upgradePurchased = 'upgrade_purchased';
  static const String departmentRestored = 'department_restored';
  static const String dailyAttempt = 'daily_attempt';
  static const String adRequested = 'ad_requested';
  static const String adShown = 'ad_shown';
  static const String adRewarded = 'ad_rewarded';
  static const String adFailed = 'ad_failed';
  static const String settingsChanged = 'settings_changed';
}
