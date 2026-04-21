import '../../../domain/models/hazard.dart';
import '../../../domain/models/package.dart';
import '../../../domain/models/shift_result.dart';

sealed class GameEvent {
  const GameEvent();
}

final class PackageSpawnedEvent extends GameEvent {
  const PackageSpawnedEvent(this.pkg);
  final GamePackage pkg;
}

final class PackageResolvedEvent extends GameEvent {
  const PackageResolvedEvent({required this.pkg, required this.outcome});
  final GamePackage pkg;
  final SortOutcome outcome;
}

final class ComboChangedEvent extends GameEvent {
  const ComboChangedEvent({required this.combo, required this.multiplier});
  final int combo;
  final double multiplier;
}

final class HazardStartedEvent extends GameEvent {
  const HazardStartedEvent(this.kind);
  final HazardKind kind;
}

final class HazardEndedEvent extends GameEvent {
  const HazardEndedEvent(this.kind);
  final HazardKind kind;
}

final class ShiftEndedEvent extends GameEvent {
  const ShiftEndedEvent(this.result);
  final ShiftResult result;
}

/// Emitted when a package arrives at the gate and waits for player routing.
/// Also emitted with `pkg == null` when the gate clears.
final class PendingPackageChangedEvent extends GameEvent {
  const PendingPackageChangedEvent(this.pkg);
  final GamePackage? pkg;
}
