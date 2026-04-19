import 'dart:developer' as dev;

/// Lightweight leveled logger. Avoids `print` so release builds stay clean.
///
/// In release we only forward warning+; in debug we forward everything.
/// Swap implementation later (e.g. Crashlytics breadcrumbs) without touching
/// call sites.
class AppLogger {
  AppLogger(this.tag);

  final String tag;

  static bool verbose = true;

  void d(Object? message) {
    if (!verbose) return;
    _emit('D', message);
  }

  void i(Object? message) => _emit('I', message);

  void w(Object? message) => _emit('W', message);

  void e(Object? message, [Object? error, StackTrace? stack]) {
    _emit('E', message, error: error, stack: stack);
  }

  void _emit(
    String level,
    Object? message, {
    Object? error,
    StackTrace? stack,
  }) {
    dev.log(
      '$message',
      name: '$level/$tag',
      error: error,
      stackTrace: stack,
    );
  }
}
