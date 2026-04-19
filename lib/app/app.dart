import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../di/providers.dart';
import 'app_lifecycle.dart';
import 'app_theme.dart';

/// Root widget. Consumes the router + flavor providers so flavor-gated
/// routes (e.g. `/debug` in release) evaporate without surfacing at all.
class DeadDispatchApp extends ConsumerWidget {
  const DeadDispatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final router = ref.watch(appRouterProvider);
    return AppLifecycleHost(
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.dark(largeText: profile.settings.largeText),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Kept as a runtime accessor in case presentation code needs to push
/// routes imperatively (e.g. from a Flame overlay that doesn't have a
/// BuildContext). In idiomatic go_router use, prefer `context.go(...)`.
GoRouter appRouter(WidgetRef ref) => ref.read(appRouterProvider);
