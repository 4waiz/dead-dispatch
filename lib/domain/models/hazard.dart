/// Things that go wrong during a shift. Hazards are scheduled by the
/// `HazardSystem` based on shift difficulty.
enum HazardKind {
  beltJam,
  powerFlicker,
  misrouteChain,
  surgeRush,
  blackout,
  vipWave;

  String get key => name;

  static HazardKind fromKey(String key) =>
      HazardKind.values.firstWhere((h) => h.key == key,
          orElse: () => HazardKind.beltJam);
}

class HazardDescriptor {
  const HazardDescriptor({
    required this.kind,
    required this.duration,
    required this.severity,
    required this.tutorialHint,
  });

  final HazardKind kind;
  final Duration duration;

  /// 0..1 — how disruptive. Drives screen shake amplitude, audio mix, etc.
  final double severity;

  final String tutorialHint;

  factory HazardDescriptor.fromJson(Map<String, Object?> j) => HazardDescriptor(
        kind: HazardKind.fromKey(j['kind']! as String),
        duration: Duration(milliseconds: (j['durationMs']! as num).toInt()),
        severity: (j['severity']! as num).toDouble(),
        tutorialHint: j['tutorialHint']! as String,
      );
}

/// Active hazard on the running shift.
class ActiveHazard {
  ActiveHazard({
    required this.kind,
    required this.startedAt,
    required this.endsAt,
  });

  final HazardKind kind;
  final Duration startedAt;
  final Duration endsAt;

  bool isActiveAt(Duration t) => t >= startedAt && t < endsAt;
}
