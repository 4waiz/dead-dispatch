import 'dart:async';

import '../../../domain/balance/balance_data.dart';
import '../../../domain/models/hazard.dart';
import '../../../domain/models/package.dart';
import '../../../domain/models/shift_config.dart';
import '../../../domain/models/shift_result.dart';
import '../../../domain/services/score_service.dart';
import '../../../domain/services/seeded_random.dart';
import 'game_events.dart';
import 'game_state.dart';

/// Orchestrates one shift: owns the authoritative [GameState], [ScoreService],
/// and [SeededRandom]. Flame systems call into this to spawn packages, trigger
/// hazards, and resolve routing. [GameScreen] listens to [events] to update
/// the HUD.
class GameSession {
  GameSession({
    required ShiftConfig config,
    required BalanceData balance,
  })  : _config = config,
        _score = ScoreService(balance),
        _rng = SeededRandom(config.seed) {
    final stamps = config.modifiers.contains(ShiftModifier.doubleStamps) ? 6 : 3;
    _state = GameState(
      elapsed: Duration.zero,
      remaining: config.duration,
      activeHazards: const {},
      stamps: stamps,
      paused: false,
    );
  }

  final ShiftConfig _config;
  final ScoreService _score;
  final SeededRandom _rng;

  late GameState _state;
  bool _started = false;
  bool _ended = false;

  GamePackage? _pendingPackage;

  final _controller = StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get events => _controller.stream;
  GameState get state => _state;
  ScoreService get score => _score;
  SeededRandom get rng => _rng;
  ShiftConfig get config => _config;

  /// Package currently stopped at the gate awaiting a routing decision.
  GamePackage? get pendingPackage => _pendingPackage;

  void start() {
    if (_started || _ended) return;
    _started = true;
  }

  void pause() {
    if (!_started || _ended || _state.paused) return;
    _state = _state.copyWith(paused: true);
  }

  void resume() {
    if (!_started || _ended || !_state.paused) return;
    _state = _state.copyWith(paused: false);
  }

  /// Called each Flame frame from [DeadDispatchGame.update].
  void tick(double dt) {
    if (!_started || _ended || _state.paused) return;
    final addMs = (dt * 1000).round();
    final elapsed = Duration(milliseconds: _state.elapsed.inMilliseconds + addMs);
    var remaining = _config.duration - elapsed;
    if (remaining.isNegative) remaining = Duration.zero;
    _state = _state.copyWith(elapsed: elapsed, remaining: remaining);
    if (remaining == Duration.zero) _end();
  }

  // ---------------------------------------------------------------------------
  // Package events
  // ---------------------------------------------------------------------------

  void onPackageSpawned(GamePackage pkg) {
    if (_ended) return;
    _controller.add(PackageSpawnedEvent(pkg));
  }

  void setPendingPackage(GamePackage pkg) {
    _pendingPackage = pkg;
    _controller.add(PendingPackageChangedEvent(pkg));
  }

  void clearPendingPackage() {
    _pendingPackage = null;
    _controller.add(const PendingPackageChangedEvent(null));
  }

  void onPackageResolved(GamePackage pkg, SortOutcome outcome) {
    if (_ended) return;
    final prevCombo = _score.combo;
    _score.registerOutcome(package: pkg, outcome: outcome);
    _controller.add(PackageResolvedEvent(pkg: pkg, outcome: outcome));
    if (_score.combo != prevCombo || outcome == SortOutcome.miss || outcome == SortOutcome.destroyed) {
      _controller.add(
        ComboChangedEvent(
          combo: _score.combo,
          multiplier: _score.comboMultiplier,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Stamp
  // ---------------------------------------------------------------------------

  /// Returns true if stamp was consumed; false if out of stamps or inapplicable.
  bool consumeStamp(GamePackage pkg) {
    if (_state.stamps <= 0) return false;
    if (!_score.isStampApplicableTo(pkg.type)) return false;
    _state = _state.copyWith(stamps: _state.stamps - 1);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Hazard events — called by HazardSystem
  // ---------------------------------------------------------------------------

  void onHazardStarted(HazardKind kind) {
    if (_ended) return;
    final updated = Set<HazardKind>.from(_state.activeHazards)..add(kind);
    _state = _state.copyWith(activeHazards: updated);
    _controller.add(HazardStartedEvent(kind));
  }

  void onHazardEnded(HazardKind kind) {
    if (_ended) return;
    final updated = Set<HazardKind>.from(_state.activeHazards)..remove(kind);
    _state = _state.copyWith(activeHazards: updated);
    _controller.add(HazardEndedEvent(kind));
  }

  // ---------------------------------------------------------------------------
  // Termination
  // ---------------------------------------------------------------------------

  void _end() {
    if (_ended) return;
    _ended = true;
    final result = ShiftResult(
      shiftId: _config.id,
      score: _score.score,
      combo: _score.combo,
      maxCombo: _score.maxCombo,
      coins: _score.coinTotal,
      records: _score.records.toList(),
      completed: _score.score >= _config.targetScore,
      failureReason: _score.score < _config.targetScore ? 'score' : null,
      duration: _state.elapsed,
    );
    _controller.add(ShiftEndedEvent(result));
  }

  void dispose() {
    _controller.close();
  }
}
