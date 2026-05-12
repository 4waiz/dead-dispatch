import '../balance/balance_data.dart';
import '../models/block_type.dart';
import '../models/hazard.dart';
import '../models/player_profile.dart';
import '../models/shift_config.dart';
import 'daily_seed.dart';
import 'seeded_random.dart';

/// Builds [ShiftConfig] for both Classic Shifts and Daily Seal runs.
///
/// Difficulty is driven by `progressionLevel` — derived from
/// totalShiftsPlayed + restored departments — not by wall-clock time.
/// That keeps it fair for returning players.
class DifficultyService {
  const DifficultyService(this._balance);

  final BalanceData _balance;

  int progressionLevelFor(PlayerProfile profile) {
    final shifts = profile.totalShiftsPlayed;
    final dept = profile.restoredDepartments.length;
    return (shifts ~/ 3) + (dept * 2);
  }

  ShiftConfig buildClassic(PlayerProfile profile, {int? overrideSeed}) {
    final level = progressionLevelFor(profile);
    final seed = overrideSeed ?? _stableSeedFor(profile, level);
    return _build(
      id: 'shift-$level-${profile.totalShiftsPlayed}',
      seed: seed,
      level: level,
      isDaily: false,
      dailyModifier: null,
    );
  }

  ShiftConfig buildDaily(PlayerProfile profile, {String? dateKey}) {
    final key = dateKey ?? DailySeed.todayKey();
    final seed = DailySeed.seedFor(key);
    final rng = SeededRandom(seed);

    final level = progressionLevelFor(profile) + 2;
    const pool = HazardKind.values;
    final modifier = pool[rng.nextIntRange(0, pool.length)];

    return _build(
      id: 'daily-$key',
      seed: seed,
      level: level,
      isDaily: true,
      dailyModifier: modifier,
    );
  }

  ShiftConfig _build({
    required String id,
    required int seed,
    required int level,
    required bool isDaily,
    required HazardKind? dailyModifier,
  }) {
    final shifts = _balance.shifts;

    final allowedTypes = <BlockType>[
      ...shifts.unlockOrder.take(2 + (level ~/ 2)),
    ];
    if (allowedTypes.isEmpty) allowedTypes.add(BlockType.standard);

    final targetScore =
        (shifts.baseTargetScore * _pow(shifts.targetScoreGrowth, level))
            .round();

    return ShiftConfig(
      id: id,
      seed: seed,
      gridSize: shifts.gridSize,
      pieceQueueSize: shifts.pieceQueueSize,
      targetScore: targetScore,
      allowedTypes: allowedTypes,
      isDaily: isDaily,
      duration: isDaily ? shifts.dailyDuration : null,
      dailyModifier: dailyModifier,
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
