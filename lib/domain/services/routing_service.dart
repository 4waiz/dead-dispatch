import '../balance/balance_data.dart';
import '../models/package.dart';
import '../models/package_type.dart';

/// Decides whether the lane the player picked matches the parcel's correct
/// destination. Pure domain logic — no Flame, no Flutter. The Phase 2
/// gameplay loop consults this; tests cover every package type.
class RoutingService {
  const RoutingService(this._balance);

  final BalanceData _balance;

  /// Compute the outcome for a package that has reached its destination
  /// lane. `actualLane` may be null if the player let the parcel fall off
  /// the belt without choosing a lane.
  SortOutcome resolve({
    required GamePackage package,
    required String? actualLane,
  }) {
    final desc = _balance.packageOf(package.type);

    if (package.type == PackageType.duplicate) {
      // Duplicates are *meant* to be shredded.
      return actualLane == 'shred'
          ? SortOutcome.perfect
          : SortOutcome.miss;
    }

    if (package.type == PackageType.decaying) {
      if (package.decayProgress >= 0.95) return SortOutcome.destroyed;
      return actualLane == 'incinerator'
          ? SortOutcome.perfect
          : SortOutcome.miss;
    }

    if (package.type == PackageType.mislabeled) {
      // Mislabeled mail must go to review *unless* the player stamped it
      // correctly, in which case any non-shred lane is acceptable.
      if (actualLane == 'review') return SortOutcome.perfect;
      if (package.stamped && actualLane != 'shred') {
        return SortOutcome.acceptable;
      }
      return SortOutcome.miss;
    }

    if (actualLane == null) return SortOutcome.miss;

    if (actualLane == desc.lane) {
      // Priority parcels need a stamp for the perfect bonus.
      if (package.type == PackageType.priority) {
        return package.stamped ? SortOutcome.perfect : SortOutcome.acceptable;
      }
      return SortOutcome.perfect;
    }

    if (package.type == PackageType.fragile && actualLane != desc.lane) {
      return SortOutcome.destroyed;
    }

    return SortOutcome.miss;
  }
}
