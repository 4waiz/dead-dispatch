import '../../../../domain/models/hazard.dart';
import '../dead_dispatch_game.dart';
import '../game_session.dart';

/// Schedules and manages hazard lifecycle. Uses [SeededRandom] for timing
/// so daily challenges reproduce the same hazard sequence on every device.
class HazardSystem {
  HazardSystem({required this.session, required this.game}) {
    _scheduleNext();
  }

  final GameSession session;
  final DeadDispatchGame game;

  double _timeUntilHazard = 0;
  final List<_ActiveEntry> _active = [];

  void _scheduleNext() {
    // 8–18 s between hazard triggers
    _timeUntilHazard = 8.0 + session.rng.nextDouble() * 10.0;
  }

  void tick(double dt) {
    if (session.state.paused) return;

    // Expire active hazards
    for (var i = _active.length - 1; i >= 0; i--) {
      _active[i].remaining -= dt;
      if (_active[i].remaining <= 0) {
        session.onHazardEnded(_active[i].kind);
        _active.removeAt(i);
      }
    }

    if (session.config.allowedHazards.isEmpty) return;

    _timeUntilHazard -= dt;
    if (_timeUntilHazard > 0) return;

    _trigger();
    _scheduleNext();
  }

  void _trigger() {
    final available = session.config.allowedHazards
        .where((h) => !session.state.activeHazards.contains(h))
        .toList();
    if (available.isEmpty) return;

    // Lower-severity hazards are more likely (inverted weighting)
    final weights = available.map((h) {
      final severity = game.balance.hazardOf(h)?.severity ?? 0.5;
      return 1.0 - severity + 0.1;
    }).toList();

    final kind = session.rng.weightedPick(available, weights);
    final descriptor = game.balance.hazardOf(kind);
    final durationSecs = (descriptor?.duration.inMilliseconds ?? 4000) / 1000.0;

    _active.add(_ActiveEntry(kind: kind, remaining: durationSecs));
    session.onHazardStarted(kind);
  }
}

class _ActiveEntry {
  _ActiveEntry({required this.kind, required this.remaining});
  final HazardKind kind;
  double remaining;
}
