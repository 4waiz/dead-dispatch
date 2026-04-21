import '../../../../domain/models/hazard.dart';
import '../../../../domain/models/package.dart';
import '../../../../domain/models/package_type.dart';
import '../components/package_component.dart';
import '../dead_dispatch_game.dart';
import '../game_session.dart';

/// Schedules package spawns based on [ShiftConfig.spawnInterval] and jitter.
/// Allocation-free hot path: no lists or closures created during tick().
class SpawnerSystem {
  SpawnerSystem({required this.session, required this.game}) {
    _resetTimer();
  }

  final GameSession session;
  final DeadDispatchGame game;

  int _nextId = 0;
  double _timeUntilSpawn = 0;

  void _resetTimer() {
    final cfg = session.config;
    final baseS = cfg.spawnInterval.inMilliseconds / 1000.0;
    final jitterS = cfg.spawnIntervalJitter.inMilliseconds / 1000.0;
    final roll = session.rng.nextDouble() * jitterS * 2 - jitterS;
    _timeUntilSpawn = (baseS + roll).clamp(0.3, 10.0);
  }

  void tick(double dt) {
    if (session.state.paused) return;

    // surgeRush doubles effective spawn rate
    final speedMul =
        session.state.activeHazards.contains(HazardKind.surgeRush) ? 2.0 : 1.0;
    _timeUntilSpawn -= dt * speedMul;
    if (_timeUntilSpawn > 0) return;

    if (game.activePackageCount >= session.config.maxConcurrentPackages) {
      _timeUntilSpawn = 0.5;
      return;
    }

    _spawn();
    _resetTimer();
  }

  void _spawn() {
    final types = session.config.allowedTypes;
    if (types.isEmpty) return;

    PackageType type;
    if (session.state.activeHazards.contains(HazardKind.vipWave)) {
      final vip = types
          .where(
            (t) => t == PackageType.priority || t == PackageType.ghost,
          )
          .toList();
      type = vip.isNotEmpty ? session.rng.pick(vip) : session.rng.pick(types);
    } else {
      type = session.rng.pick(types);
    }

    final beltIndex = session.rng.nextIntRange(0, 2);
    final pkg = GamePackage(
      id: _nextId++,
      type: type,
      spawnedAt: session.state.elapsed,
    );
    final component = PackageComponent(
      pkg: pkg,
      beltIndex: beltIndex,
      beltSpeedMultiplier: session.config.beltSpeedMultiplier,
    );
    game.addPackage(component);
    session.onPackageSpawned(pkg);
  }
}
