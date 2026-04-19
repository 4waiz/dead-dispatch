import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/shift_result.dart';
import '../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../features/debug/presentation/debug_screen.dart';
import '../features/gameplay/presentation/game_screen.dart';
import '../features/menu/presentation/main_menu_screen.dart';
import '../features/meta/presentation/department_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shift_brief/presentation/shift_brief_screen.dart';
import '../features/shift_result/presentation/shift_result_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/tutorial/presentation/tutorial_screen.dart';
import '../features/upgrades/presentation/upgrade_screen.dart';
import '../presentation/widgets/error_boundary.dart';

/// go_router configuration. Named paths are preferred for testability and
/// deep-link support. Every top-level route is wrapped in [ErrorBoundary]
/// so a crash in one screen never bricks navigation.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String menu = '/menu';
  static const String tutorial = '/tutorial';
  static const String brief = '/brief';
  static const String game = '/game';
  static const String result = '/result';
  static const String upgrades = '/upgrades';
  static const String departments = '/departments';
  static const String daily = '/daily';
  static const String settings = '/settings';
  static const String debug = '/debug';
}

GoRouter buildAppRouter({required bool showDebugMenu}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _Boundary(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (_, __) => const _Boundary(child: MainMenuScreen()),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, __) => const _Boundary(child: TutorialScreen()),
      ),
      GoRoute(
        path: AppRoutes.brief,
        builder: (_, state) => _Boundary(
          child: ShiftBriefScreen(
            dailyDateKey: state.uri.queryParameters['daily'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (_, state) => _Boundary(
          child: GameScreen(
            dailyDateKey: state.uri.queryParameters['daily'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! ShiftResult) {
            return const _Boundary(child: _MissingResult());
          }
          return _Boundary(child: ShiftResultScreen(result: extra));
        },
      ),
      GoRoute(
        path: AppRoutes.upgrades,
        builder: (_, __) => const _Boundary(child: UpgradeScreen()),
      ),
      GoRoute(
        path: AppRoutes.departments,
        builder: (_, __) => const _Boundary(child: DepartmentScreen()),
      ),
      GoRoute(
        path: AppRoutes.daily,
        builder: (_, __) => const _Boundary(child: DailyChallengeScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const _Boundary(child: SettingsScreen()),
      ),
      if (showDebugMenu)
        GoRoute(
          path: AppRoutes.debug,
          builder: (_, __) => const _Boundary(child: DebugScreen()),
        ),
    ],
    errorBuilder: (_, state) => _Boundary(
      child: _RouteError(message: state.error?.toString() ?? 'Unknown route'),
    ),
  );
}

class _Boundary extends StatelessWidget {
  const _Boundary({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ErrorBoundary(child: child);
}

class _MissingResult extends StatelessWidget {
  const _MissingResult();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Missing shift result payload.')),
      );
}

class _RouteError extends StatelessWidget {
  const _RouteError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text('Route error: $message')),
      );
}
