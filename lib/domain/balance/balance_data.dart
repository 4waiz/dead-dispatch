import '../models/block_type.dart';
import '../models/department.dart';
import '../models/hazard.dart';
import '../models/upgrade.dart';

/// In-memory snapshot of all balancing data, hydrated from JSON at boot.
/// Treat as immutable. Hot-reload friendly: rebuild via [BalanceProvider].
class BalanceData {
  const BalanceData({
    required this.shifts,
    required this.blocks,
    required this.hazards,
    required this.upgrades,
    required this.departments,
    required this.economy,
  });

  final ShiftBalance shifts;
  final Map<BlockType, BlockDescriptor> blocks;
  final Map<HazardKind, HazardDescriptor> hazards;
  final Map<UpgradeKind, UpgradeDescriptor> upgrades;
  final List<DepartmentDescriptor> departments;
  final EconomyBalance economy;

  BlockDescriptor blockOf(BlockType t) =>
      blocks[t] ?? blocks[BlockType.standard]!;

  HazardDescriptor? hazardOf(HazardKind h) => hazards[h];

  UpgradeDescriptor? upgradeOf(UpgradeKind u) => upgrades[u];
}

/// Board + scoring tunables. Conveyor-era spawn fields have been removed.
class ShiftBalance {
  const ShiftBalance({
    required this.gridSize,
    required this.pieceQueueSize,
    required this.baseTargetScore,
    required this.targetScoreGrowth,
    required this.unlockOrder,
    required this.classicNoTimer,
    required this.dailyDuration,
  });

  final int gridSize;
  final int pieceQueueSize;
  final int baseTargetScore;
  final double targetScoreGrowth;
  final List<BlockType> unlockOrder;
  final bool classicNoTimer;

  /// Optional duration cap for daily mode. Null = endless.
  final Duration? dailyDuration;

  factory ShiftBalance.fromJson(Map<String, Object?> j) => ShiftBalance(
        gridSize: (j['gridSize'] as num?)?.toInt() ?? 8,
        pieceQueueSize: (j['pieceQueueSize'] as num?)?.toInt() ?? 3,
        baseTargetScore: (j['baseTargetScore']! as num).toInt(),
        targetScoreGrowth: (j['targetScoreGrowth']! as num).toDouble(),
        unlockOrder: (j['unlockOrder']! as List)
            .cast<String>()
            .map(BlockType.fromKey)
            .toList(growable: false),
        classicNoTimer: j['classicNoTimer'] as bool? ?? true,
        dailyDuration: (j['dailyDurationMs'] as num?) == null
            ? null
            : Duration(
                milliseconds: (j['dailyDurationMs']! as num).toInt(),
              ),
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
    required this.clearLineBonus,
    required this.multiClearBonusPerExtraLine,
    required this.perfectClearBonus,
  });

  final double coinPerScorePoint;

  /// Reserved — small additive bonus on certain placements (currently
  /// awarded when a piece triggers any clear at all).
  final int perfectBonus;
  final double comboMultiplierStep;
  final double comboMultiplierCap;
  final int dailyCompletionBonus;
  final double failureForgivenessRefund;
  final int mysteryParcelMin;
  final int mysteryParcelMax;

  /// Flat score added per line cleared by a single placement.
  final int clearLineBonus;

  /// Extra score per additional line in the same placement (line #2+).
  final int multiClearBonusPerExtraLine;

  /// Bonus awarded when a placement leaves the board empty.
  final int perfectClearBonus;

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
        clearLineBonus: (j['clearLineBonus'] as num?)?.toInt() ?? 30,
        multiClearBonusPerExtraLine:
            (j['multiClearBonusPerExtraLine'] as num?)?.toInt() ?? 60,
        perfectClearBonus: (j['perfectClearBonus'] as num?)?.toInt() ?? 200,
      );
}
