/// All canonical mail varieties. Adding a new type:
///   1. Add an enum value here.
///   2. Register routing rules in `RoutingSystem`.
///   3. Add a sprite key + audio cue in `assets/config/packages.json`.
///   4. Add balance values to `assets/config/packages.json`.
enum PackageType {
  standard,
  priority,
  fragile,
  frozen,
  ghost,
  mislabeled,
  duplicate,
  decaying;

  /// Stable string used in JSON / saves. Renaming an enum case must NOT
  /// change this string — bump save schema instead.
  String get key => name;

  static PackageType fromKey(String key) =>
      PackageType.values.firstWhere((p) => p.key == key,
          orElse: () => PackageType.standard);
}

/// Static descriptor loaded from `assets/config/packages.json`.
class PackageDescriptor {
  const PackageDescriptor({
    required this.type,
    required this.baseScore,
    required this.baseSpeed,
    required this.fragility,
    required this.canStamp,
    required this.timedDecay,
    required this.lane,
    required this.colorHex,
  });

  final PackageType type;
  final int baseScore;
  final double baseSpeed;
  final double fragility;
  final bool canStamp;
  final bool timedDecay;
  final String lane; // canonical sort lane key (e.g. "north", "vault", "void")
  final String colorHex;

  factory PackageDescriptor.fromJson(Map<String, Object?> j) =>
      PackageDescriptor(
        type: PackageType.fromKey(j['type']! as String),
        baseScore: (j['baseScore']! as num).toInt(),
        baseSpeed: (j['baseSpeed']! as num).toDouble(),
        fragility: (j['fragility']! as num).toDouble(),
        canStamp: j['canStamp']! as bool,
        timedDecay: j['timedDecay']! as bool,
        lane: j['lane']! as String,
        colorHex: j['colorHex']! as String,
      );
}
