import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/difficulty_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _balance = BalanceData(
  shifts: ShiftBalance(
    gridSize: 8,
    pieceQueueSize: 3,
    baseTargetScore: 600,
    targetScoreGrowth: 1.18,
    unlockOrder: [
      BlockType.standard,
      BlockType.priority,
      BlockType.fragile,
      BlockType.frozen,
    ],
    classicNoTimer: true,
    dailyDuration: null,
  ),
  blocks: <BlockType, BlockDescriptor>{},
  hazards: <HazardKind, HazardDescriptor>{},
  upgrades: <UpgradeKind, UpgradeDescriptor>{},
  departments: <DepartmentDescriptor>[],
  economy: EconomyBalance(
    coinPerScorePoint: 0.1,
    perfectBonus: 0,
    comboMultiplierStep: 0,
    comboMultiplierCap: 1.0,
    dailyCompletionBonus: 0,
    failureForgivenessRefund: 0,
    mysteryParcelMin: 10,
    mysteryParcelMax: 30,
    clearLineBonus: 30,
    multiClearBonusPerExtraLine: 60,
    perfectClearBonus: 200,
  ),
);

void main() {
  group('DifficultyService', () {
    const svc = DifficultyService(_balance);

    test('early shifts have a smaller allowed-block pool', () {
      final profile = PlayerProfile.fresh(1);
      final cfg = svc.buildClassic(profile);
      // Level 0 → 2 allowed types (floor of unlockOrder).
      expect(cfg.allowedTypes.length, lessThanOrEqualTo(3));
      expect(cfg.allowedTypes, contains(BlockType.standard));
    });

    test('progressionLevel increases with totalShiftsPlayed', () {
      final profile = PlayerProfile.fresh(1);
      final early = svc.progressionLevelFor(profile);
      profile.totalShiftsPlayed = 15;
      final later = svc.progressionLevelFor(profile);
      expect(later, greaterThan(early));
    });

    test('target score grows with level', () {
      final profile = PlayerProfile.fresh(1);
      final base = svc.buildClassic(profile).targetScore;
      profile.totalShiftsPlayed = 20;
      final harder = svc.buildClassic(profile).targetScore;
      expect(harder, greaterThan(base));
    });

    test('buildClassic produces the configured grid size + queue size', () {
      final profile = PlayerProfile.fresh(1);
      final cfg = svc.buildClassic(profile);
      expect(cfg.gridSize, 8);
      expect(cfg.pieceQueueSize, 3);
      expect(cfg.isDaily, isFalse);
      expect(cfg.dailyModifier, isNull);
    });

    test('daily challenge is deterministic for a date', () {
      final profile = PlayerProfile.fresh(1);
      final a = svc.buildDaily(profile, dateKey: '2026-04-19');
      final b = svc.buildDaily(profile, dateKey: '2026-04-19');
      expect(a.seed, b.seed);
      expect(a.dailyModifier, b.dailyModifier);
      expect(a.isDaily, isTrue);
    });

    test('different daily dates → different seeds', () {
      final profile = PlayerProfile.fresh(1);
      final a = svc.buildDaily(profile, dateKey: '2026-04-19');
      final b = svc.buildDaily(profile, dateKey: '2026-04-20');
      expect(a.seed, isNot(b.seed));
    });
  });
}
