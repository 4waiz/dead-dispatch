import 'app/bootstrap.dart';

/// Entry point. All real work happens in [bootstrap] — keeping `main`
/// tiny makes it trivial to build alternate flavors (e.g. a standalone
/// benchmark harness) that reuse the rest of the app.
Future<void> main() async => bootstrap();
