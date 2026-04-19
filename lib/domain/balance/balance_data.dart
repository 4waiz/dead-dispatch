import '../models/department.dart';
import '../models/hazard.dart';
import '../models/package_type.dart';
import '../models/upgrade.dart';

/// In-memory snapshot of all balancing data, hydrated from JSON at boot.
/// Treat as immutable. Hot-reload friendly: rebuild via [BalanceProvider].
class BalanceData {
  const BalanceData({
    required this.shifts,
    required this.packages,
    required this.hazards,
    required this.upgrades,
    required this.departments,
    required this.economy,
  });

  final ShiftBalance shifts;
  final Map<PackageType, PackageDescriptor> packages;
  final Map<HazardKind, HazardDescriptor> hazards;
  final Map<UpgradeKind, UpgradeDescriptor> upgrades;
  final List<DepartmentDescriptor> departments;
  final EconomyBalance economy;

  PackageDescriptor packageOf(PackageType t) =>
      packages[t] ?? packages[PackageType.standard]!;

  HazardDescriptor? hazardOf(HazardKind h) => hazards[h];

  UpgradeDescriptor? upgradeOf(UpgradeKind u) => upgrades[u];
}

class ShiftBalance {
  const ShiftBalance({
    required this.baseDuration,
    required this.baseSpawnInterval,
    required this.minSpawnInterval,
    required this.spawnIntervalDecayPerLevel,
    required this.baseTargetScore,
    required this.targetScoreGrowth,
    required this.unlockOrder,
    required this.maxConcurrentBase,
    required this.maxConcurrentGrowthEvery,
  });

  final Duration baseDuration;
  final Duration baseSpawnInterval;
  final Duration minSpawnInterval;
  final Duration spawnIntervalDecayPerLevel;
  final int baseTargetScore;
  final double targetScoreGrowth;
  final List<PackageType> unlockOrder;
  final int maxConcurrentBase;

  /// Add +1 max concurrent every N difficulty levels.
  final int maxConcurrentGrowthEvery;

  factory ShiftBalance.fromJson(Map<String, Object?> j) => ShiftBalance(
        baseDuration:
            Duration(milliseconds: (j['baseDurationMs']! as num).toInt()),
        baseSpawnInterval:
            Duration(milliseconds: (j['baseSpawnIntervalMs']! as num).toInt()),
        minSpawnInterval:
            Duration(milliseconds: (j['minSpawnIntervalMs']! as num).toInt()),
        spawnIntervalDecayPerLevel: Duration(
            milliseconds:
                (j['spawnIntervalDecayPerLevelMs']! as num).toInt()),
        baseTargetScore: (j['baseTargetScore']! as num).toInt(),
        targetScoreGrowth: (j['targetScoreGrowth']! as num).toDouble(),
        unlockOrder: (j['unlockOrder']! as List)
            .cast<String>()
            .map(PackageType.fromKey)
            .toList(growable: false),
        maxConcurrentBase: (j['maxConcurrentBase']! as num).toInt(),
        maxConcurrentGrowthEvery:
            (j['maxConcurrentGrowthEvery']! as num).toInt(),
      );
}

class EconomyBalance {
  const EconomyBalance({
    required this.coinPerScorePoint,
    required this.perfectBonus,
    required this.comboMultiplierStep,
    required this.comboMultiplierCap,
    required this.dailyCompletionBonus,
    required this.failureForgivenessRefund,
    required this.mysteryParcelMin,
    required this.mysteryParcelMax,
  });

  final double coinPerScorePoint;
  final int perfectBonus;
  final double comboMultiplierStep;
  final double comboMultiplierCap;
  final int dailyCompletionBonus;
  final double failureForgivenessRefund;
  final int mysteryParcelMin;
  final int mysteryParcelMax;

  factory EconomyBalance.fromJson(Map<String, Object?> j) => EconomyBalance(
        coinPerScorePoint: (j['coinPerScorePoint']! as num).toDouble(),
        perfectBonus: (j['perfectBonus']! as num).toInt(),
        comboMultiplierStep: (j['comboMultiplierStep']! as num).toDouble(),
        comboMultiplierCap: (j['comboMultiplierCap']! as num).toDouble(),
        dailyCompletionBonus: (j['dailyCompletionBonus']! as num).toInt(),
        failureForgivenessRefund:
            (j['failureForgivenessRefund']! as num).toDouble(),
        mysteryParcelMin: (j['mysteryParcelMin']! as num).toInt(),
        mysteryParcelMax: (j['mysteryParcelMax']! as num).toInt(),
      );
}
