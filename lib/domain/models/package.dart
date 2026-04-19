import 'package_type.dart';

/// Runtime instance of a single parcel travelling through the sorting office.
/// Lives in domain so spawner/score logic can be unit-tested without Flame.
class GamePackage {
  GamePackage({
    required this.id,
    required this.type,
    required this.spawnedAt,
    this.stamped = false,
    this.lane,
    this.decayProgress = 0,
  });

  final int id;
  final PackageType type;
  final Duration spawnedAt;

  /// Whether the player applied a "priority" stamp before exit.
  bool stamped;

  /// Player-chosen lane at the most recent gate (`null` until routed).
  String? lane;

  /// 0..1 — how rotted/spoiled this parcel is. Used for decaying mail.
  double decayProgress;

  GamePackage copyWith({bool? stamped, String? lane, double? decayProgress}) =>
      GamePackage(
        id: id,
        type: type,
        spawnedAt: spawnedAt,
        stamped: stamped ?? this.stamped,
        lane: lane ?? this.lane,
        decayProgress: decayProgress ?? this.decayProgress,
      );
}

/// Outcome of a single parcel reaching the end of the belt.
enum SortOutcome {
  perfect,
  acceptable,
  miss,
  destroyed;
}

class SortRecord {
  const SortRecord({
    required this.packageId,
    required this.type,
    required this.outcome,
    required this.scoreDelta,
    required this.coinDelta,
  });

  final int packageId;
  final PackageType type;
  final SortOutcome outcome;
  final int scoreDelta;
  final int coinDelta;
}
