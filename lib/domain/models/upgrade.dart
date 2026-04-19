import 'currency.dart';

/// Persistent meta-upgrades. Distinct from per-run boosts (those live
/// alongside [ShiftConfig.modifiers]). Keeps the spec rule:
/// > "Permanent upgrades and per-run bonuses must be separated cleanly."
enum UpgradeKind {
  beltSpeedTolerance,
  comboGrace,
  stampSupply,
  fragileShield,
  payoutMultiplier,
  hazardWarning,
  autoSorter,
  ghostBeacon;

  String get key => name;

  static UpgradeKind fromKey(String key) =>
      UpgradeKind.values.firstWhere((u) => u.key == key,
          orElse: () => UpgradeKind.beltSpeedTolerance);
}

class UpgradeDescriptor {
  const UpgradeDescriptor({
    required this.kind,
    required this.maxLevel,
    required this.title,
    required this.description,
    required this.costsByLevel,
    required this.effectPerLevel,
    required this.currency,
  });

  final UpgradeKind kind;
  final int maxLevel;
  final String title;
  final String description;
  final List<int> costsByLevel; // length == maxLevel
  final List<double> effectPerLevel;
  final Currency currency;

  int costForLevel(int targetLevel) {
    if (targetLevel <= 0 || targetLevel > maxLevel) return -1;
    return costsByLevel[targetLevel - 1];
  }

  double effectForLevel(int level) {
    if (level <= 0) return 0;
    final clamped = level.clamp(1, maxLevel).toInt();
    return effectPerLevel[clamped - 1];
  }

  factory UpgradeDescriptor.fromJson(Map<String, Object?> j) =>
      UpgradeDescriptor(
        kind: UpgradeKind.fromKey(j['kind']! as String),
        maxLevel: (j['maxLevel']! as num).toInt(),
        title: j['title']! as String,
        description: j['description']! as String,
        costsByLevel: (j['costs']! as List)
            .map((e) => (e as num).toInt())
            .toList(growable: false),
        effectPerLevel: (j['effects']! as List)
            .map((e) => (e as num).toDouble())
            .toList(growable: false),
        currency: Currency.values.firstWhere(
          (c) => c.key == (j['currency'] as String? ?? 'coins'),
          orElse: () => Currency.coins,
        ),
      );
}

class OwnedUpgrade {
  const OwnedUpgrade({required this.kind, required this.level});
  final UpgradeKind kind;
  final int level;

  Map<String, Object?> toJson() => {'kind': kind.key, 'level': level};

  factory OwnedUpgrade.fromJson(Map<String, Object?> j) => OwnedUpgrade(
        kind: UpgradeKind.fromKey(j['kind']! as String),
        level: (j['level']! as num).toInt(),
      );
}
