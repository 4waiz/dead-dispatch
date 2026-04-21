import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../../core/perf/perf_monitor.dart';
import '../../../domain/balance/balance_data.dart';
import '../../../domain/models/package.dart';
import '../../../domain/services/routing_service.dart';
import '../../../presentation/theme/colors.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptics_service.dart';
import 'components/background_component.dart';
import 'components/belt_component.dart';
import 'components/hazard_overlay_component.dart';
import 'components/package_component.dart';
import 'components/particle_burst.dart';
import 'components/score_popup.dart';
import 'game_session.dart';
import 'systems/feedback_system.dart';
import 'systems/hazard_system.dart';
import 'systems/routing_system.dart';
import 'systems/spawner_system.dart';

class DeadDispatchGame extends FlameGame {
  DeadDispatchGame({
    required this.session,
    required this.balance,
    required this.audio,
    required this.haptics,
    required this.perf,
    required this.routingService,
  });

  final GameSession session;
  final BalanceData balance;
  final AudioService audio;
  final HapticsService haptics;
  final PerfMonitor perf;
  final RoutingService routingService;

  final List<PackageComponent> _packages = [];

  late final SpawnerSystem spawner;
  late final HazardSystem hazardSystem;
  late final RoutingSystem routingSystem;
  late final FeedbackSystem feedbackSystem;

  int get activePackageCount => _packages.length;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(BackgroundComponent());
    add(BeltComponent());
    add(HazardOverlayComponent());

    spawner = SpawnerSystem(session: session, game: this);
    hazardSystem = HazardSystem(session: session, game: this);
    routingSystem = RoutingSystem(
      session: session,
      game: this,
      routingService: routingService,
    );
    feedbackSystem = FeedbackSystem(
      session: session,
      audio: audio,
      haptics: haptics,
    );

    session.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    perf.record(dt * 1000);
    session.tick(dt);
    spawner.tick(dt);
    hazardSystem.tick(dt);
    routingSystem.tick(dt);

    // Remove packages that have fully exited the right edge
    for (var i = _packages.length - 1; i >= 0; i--) {
      if (_packages[i].position.x > size.x + 80) {
        _packages[i].removeFromParent();
        _packages.removeAt(i);
      }
    }
  }

  void addPackage(PackageComponent component) {
    _packages.add(component);
    add(component);
  }

  /// Returns the first package that has reached the gate and is waiting.
  PackageComponent? firstPackageAtGate() {
    for (final p in _packages) {
      if (p.status == PackageStatus.waiting) return p;
    }
    return null;
  }

  /// Marks the package as exiting, spawns a particle burst and score popup.
  void resolvePackageComponent(int packageId, SortOutcome outcome) {
    for (final p in _packages) {
      if (p.pkg.id == packageId) {
        p.status = PackageStatus.exiting;
        final pos = p.position.clone();
        add(ParticleBurst(center: pos, color: _colorForOutcome(outcome)));
        add(
          ScorePopup(
            center: pos - Vector2(0, 30),
            outcome: outcome,
            points: session.score.lastPoints,
          ),
        );
        return;
      }
    }
  }

  /// Called by the Flutter HUD when the player taps a lane button.
  void onLaneTapped(String laneKey) => routingSystem.submitRouting(laneKey);

  /// Called by the Flutter HUD stamp button.
  void onStampTapped() {
    final pending = session.pendingPackage;
    if (pending == null) return;
    if (session.consumeStamp(pending)) {
      pending.stamped = true;
    }
  }

  Color _colorForOutcome(SortOutcome outcome) {
    switch (outcome) {
      case SortOutcome.perfect:
        return AppColors.accentGold;
      case SortOutcome.acceptable:
        return AppColors.accentOk;
      case SortOutcome.miss:
        return AppColors.accentDanger;
      case SortOutcome.destroyed:
        return const Color(0xFF444455);
    }
  }

  @override
  void onRemove() {
    feedbackSystem.dispose();
    super.onRemove();
  }
}
