import '../../../domain/models/hazard.dart';

/// Authoritative runtime state for one shift. Immutable snapshot; mutated
/// only inside [GameSession] via copyWith.
class GameState {
  const GameState({
    required this.elapsed,
    required this.remaining,
    required this.activeHazards,
    required this.stamps,
    required this.paused,
  });

  final Duration elapsed;
  final Duration remaining;

  /// Hazards currently in effect.
  final Set<HazardKind> activeHazards;

  /// Priority stamps the player has left this shift.
  final int stamps;

  final bool paused;

  GameState copyWith({
    Duration? elapsed,
    Duration? remaining,
    Set<HazardKind>? activeHazards,
    int? stamps,
    bool? paused,
  }) =>
      GameState(
        elapsed: elapsed ?? this.elapsed,
        remaining: remaining ?? this.remaining,
        activeHazards: activeHazards ?? this.activeHazards,
        stamps: stamps ?? this.stamps,
        paused: paused ?? this.paused,
      );
}
