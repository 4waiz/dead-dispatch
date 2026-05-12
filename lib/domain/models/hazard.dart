/// Daily Seal modifiers — repurposed from the original "hazard" slot. Each
/// Daily Seal shift picks exactly one of these via the seeded RNG; the
/// modifier alters the starting board or scoring rules for that day only.
enum HazardKind {
  frozenFloor,
  priorityRush,
  voidSpots,
  goldenMail,
  fragileBatch;

  String get key => name;

  static HazardKind fromKey(String key) => HazardKind.values.firstWhere(
        (h) => h.key == key,
        orElse: () => HazardKind.frozenFloor,
      );
}

class HazardDescriptor {
  const HazardDescriptor({
    required this.kind,
    required this.duration,
    required this.severity,
    required this.tutorialHint,
  });

  final HazardKind kind;

  /// Carried over from the old schema; not consumed by the block puzzle
  /// today (no timer). Kept so balance.json continues to parse cleanly.
  final Duration duration;

  /// 0..1 — how intense the modifier is (number of pre-filled cells,
  /// bonus multiplier strength, etc.). Interpreted per-modifier inside
  /// `PuzzleSession`.
  final double severity;

  final String tutorialHint;

  factory HazardDescriptor.fromJson(Map<String, Object?> j) => HazardDescriptor(
        kind: HazardKind.fromKey(j['kind']! as String),
        duration: Duration(milliseconds: (j['durationMs']! as num).toInt()),
        severity: (j['severity']! as num).toDouble(),
        tutorialHint: j['tutorialHint']! as String,
      );
}
