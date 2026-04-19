import 'package:clock/clock.dart' as pkg;

/// Application time provider. Every place that needs "now" calls
/// [AppClock.now] instead of `DateTime.now()` directly. That makes tests
/// (e.g. daily challenge rollover) deterministic: wrap the call in
/// `withClock(Clock.fixed(...))`.
abstract class AppClock {
  DateTime now();
  DateTime nowUtc();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => pkg.clock.now();

  @override
  DateTime nowUtc() => pkg.clock.now().toUtc();
}

/// Test double — freezes time at construction. Useful in unit tests.
class FrozenClock implements AppClock {
  FrozenClock(this._fixed);
  final DateTime _fixed;

  @override
  DateTime now() => _fixed;

  @override
  DateTime nowUtc() => _fixed.toUtc();
}
