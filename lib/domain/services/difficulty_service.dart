import '../balance/balance_data.dart';
import '../models/hazard.dart';
import '../models/package_type.dart';
import '../models/player_profile.dart';
import '../models/shift_config.dart';
import '../models/upgrade.dart';
import 'daily_seed.dart';
import 'seeded_random.dart';

/// Builds [ShiftConfig] for both regular shifts and daily challenges.
///
/// Difficulty is driven by `progressionLevel` — derived from totalShiftsPlayed
/// + restored departments — not by wall-clock time. That keeps it fair for
/// returning players.
class DifficultyService {
  const DifficultyService(this._balance);

  final BalanceData _balance;

  int progressionLevelFor(PlayerProfile profile) {
    final shifts = profile.totalShiftsPlayed;
    final dept = profile.restoredDepartments.length;
    return (shifts ~/ 3) + (dept * 2);
  }

  ShiftConfig buildRegular(PlayerProfile profile, {int? overrideSeed}) {
    final level = progressionLevelFor(profile);
    final seed = overrideSeed ?? _stableSeedFor(profile, level);
    return _build(
      id: 'shift-$level-${profile.totalShiftsPlayed}',
      seed: seed,
      level: level,
      profile: profile,
      isDaily: false,
      forcedModifiers: const {},
    );
  }

  ShiftConfig buildDaily(PlayerProfile profile, {String? dateKey}) {
    final key = dateKey ?? DailySeed.todayKey();
    final seed = DailySeed.seedFor(key);
    final rng = SeededRandom(seed);

    final level = progressionLevelFor(profile) + 2;
    final modifiers = <ShiftModifier>{};
    final pool = ShiftModifier.values;
    final mod = pool[rng.nextIntRange(0, pool.length)];
    modifiers.add(mod);

    return _build(
      id: 'daily-$key',
      seed: seed,
      level: level,
      profile: profile,
      isDaily: true,
      forcedModifiers: modifiers,
    );
  }

  ShiftConfig _build({
    required String id,
    required int seed,
    required int level,
    required PlayerProfile profile,
    required bool isDaily,
    required Set<ShiftModifier> forcedModifiers,
  }) {
    final shifts = _balance.shifts;

    // Allowed package set grows with level using the curated unlock order.
    final allowedTypes = <PackageType>[
      ...shifts.unlockOrder.take(2 + (level ~/ 2)),
    ];
    if (allowedTypes.isEmpty) allowedTypes.add(PackageType.standard);

    // Allowed hazards grow more slowly.
    final allowedHazards = <HazardKind>[];
    if (level >= 1) allowedHazards.add(HazardKind.beltJam);
    if (level >= 3) allowedHazards.add(HazardKind.misrouteChain);
    if (level >= 5) allowedHazards.add(HazardKind.surgeRush);
    if (level >= 7) allowedHazards.add(HazardKind.powerFlicker);
    if (level >= 9) allowedHazards.add(HazardKind.vipWave);
    if (level >= 12) allowedHazards.add(HazardKind.blackout);

    final spawnIntervalMs = (shifts.baseSpawnInterval.inMilliseconds -
            shifts.spawnIntervalDecayPerLevel.inMilliseconds * level)
        .clamp(
      shifts.minSpawnInterval.inMilliseconds,
      shifts.baseSpawnInterval.inMilliseconds,
    );

    final targetScore = (shifts.baseTargetScore *
            _pow(shifts.targetScoreGrowth, level))
        .round();

    final maxConcurrent = shifts.maxConcurrentBase +
        (level ~/ shifts.maxConcurrentGrowthEvery);

    // Apply player upgrades that affect difficulty (e.g. belt speed tolerance).
    final tolerance =
        profile.upgradeLevel(UpgradeKind.beltSpeedTolerance).toDouble();
    final beltMultiplier = 1.0 + (level * 0.05) - (tolerance * 0.04);

    return ShiftConfig(
      id: id,
      seed: seed,
      duration: shifts.baseDuration,
      targetScore: targetScore,
      spawnInterval: Duration(milliseconds: spawnIntervalMs),
      spawnIntervalJitter: const Duration(milliseconds: 250),
      allowedTypes: allowedTypes,
      allowedHazards: allowedHazards,
      maxConcurrentPackages: maxConcurrent,
      beltSpeedMultiplier: beltMultiplier.clamp(0.6, 2.0),
      modifiers: forcedModifiers,
      isDaily: isDaily,
    );
  }

  int _stableSeedFor(PlayerProfile p, int level) {
    final base = p.createdAt.millisecondsSinceEpoch ^
        (level * 0x9E3779B1) ^
        (p.totalShiftsPlayed * 0x85EBCA6B);
    return base & 0xFFFFFFFF;
  }

  double _pow(double base, int exp) {
    double v = 1;
    for (var i = 0; i < exp; i++) {
      v *= base;
    }
    return v;
  }
}
