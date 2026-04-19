import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../di/providers.dart';

/// Pauses audio / persists state when the app backgrounds, and refreshes
/// remote config on resume. Mount once near the root (below [ProviderScope]).
class AppLifecycleHost extends ConsumerStatefulWidget {
  const AppLifecycleHost({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppLifecycleHost> createState() => _AppLifecycleHostState();
}

class _AppLifecycleHostState extends ConsumerState<AppLifecycleHost>
    with WidgetsBindingObserver {
  final AppLogger _log = AppLogger('Lifecycle');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.d('lifecycle → $state');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Persist the current player profile so we never lose progress on
        // abrupt foreground eviction (common on mid-range Android).
        unawaited(ref.read(playerProfileProvider.notifier).persist());
        unawaited(ref.read(audioServiceProvider).stopMusic());
      case AppLifecycleState.resumed:
        unawaited(ref.read(remoteConfigServiceProvider).refresh());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void unawaited(Future<void> _) {}
