import '../../../../domain/models/hazard.dart';
import '../../../../domain/models/package.dart';
import '../../../../domain/services/routing_service.dart';
import '../components/package_component.dart';
import '../dead_dispatch_game.dart';
import '../game_session.dart';

/// Detects when a package reaches the gate zone, arms a routing timeout,
/// and resolves the outcome once the player taps a lane (or time runs out).
class RoutingSystem {
  RoutingSystem({
    required this.session,
    required this.game,
    required this.routingService,
  });

  final GameSession session;
  final DeadDispatchGame game;
  final RoutingService routingService;

  static const double _timeoutSecs = 6.0;
  double _routingTimeout = 0;

  void tick(double dt) {
    if (session.state.paused) return;

    if (session.pendingPackage != null) {
      // beltJam freezes the clock; powerFlicker gives brief extra time
      final frozen = session.state.activeHazards.contains(HazardKind.beltJam);
      if (!frozen) _routingTimeout -= dt;
      if (_routingTimeout <= 0) {
        // Timeout — auto-miss
        _resolve(session.pendingPackage!, null);
      }
      return;
    }

    // Find the first package that has reached the gate
    final atGate = game.firstPackageAtGate();
    if (atGate != null) {
      session.setPendingPackage(atGate.pkg);
      _routingTimeout = _timeoutSecs;
    }
  }

  /// Called by [DeadDispatchGame.onLaneTapped] when the player picks a lane.
  void submitRouting(String laneKey) {
    final pending = session.pendingPackage;
    if (pending == null) return;
    final withLane = pending.copyWith(lane: laneKey);
    _resolve(withLane, laneKey);
  }

  void _resolve(GamePackage pkg, String? laneKey) {
    session.clearPendingPackage();
    final routed = laneKey != null ? pkg.copyWith(lane: laneKey) : pkg;
    final outcome =
        routingService.resolve(package: routed, actualLane: laneKey);
    session.onPackageResolved(routed, outcome);
    game.resolvePackageComponent(routed.id, outcome);
  }
}
