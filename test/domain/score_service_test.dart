import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/score_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _standardDesc = BlockDescriptor(
  type: BlockType.standard,
  baseScore: 30,
  colorHex: '#ffffff',
);

const _balance = BalanceData(
  shifts: ShiftBalance(
    gridSize: 8,
    pieceQueueSize: 3,
    baseTargetScore: 500,
    targetScoreGrowth: 1.1,
    unlockOrder: [BlockType.standard, BlockType.priority],
    classicNoTimer: true,
    dailyDuration: null,
  ),
  blocks: <BlockType, BlockDescriptor>{BlockType.standard: _standardDesc},
  hazards: <HazardKind, HazardDescriptor>{},
  upgrades: <UpgradeKind, UpgradeDescriptor>{},
  departments: <DepartmentDescriptor>[],
  economy: EconomyBalance(
    coinPerScorePoint: 0.1,
    perfectBonus: 20,
    comboMultiplierStep: 0.1,
    comboMultiplierCap: 3.0,
    dailyCompletionBonus: 0,
    failureForgivenessRefund: 0,
    mysteryParcelMin: 10,
    mysteryParcelMax: 30,
    clearLineBonus: 50,
    multiClearBonusPerExtraLine: 80,
    perfectClearBonus: 300,
  ),
);

void main() {
  group('ScoreService', () {
    test('non-clearing placement awards per-cell score and resets combo to 0',
        () {
      final svc = ScoreService(_balance);
      svc.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 3,
        linesCleared: 0,
        boardCleared: false,
      );
      expect(svc.combo, 0);
      expect(svc.score, greaterThan(0));
    });

    test('clearing a line advances combo and applies clear-line bonus', () {
      final svc = ScoreService(_balance);
      final rec = svc.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      expect(svc.combo, 1);
      expect(rec.scoreDelta, greaterThan(_balance.economy.clearLineBonus));
    });

    test('multi-line clear awards extra-line bonus', () {
      final svc = ScoreService(_balance);
      final single = ScoreService(_balance);
      single.registerPlacement(
        pieceId: 0,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      svc.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 3,
        boardCleared: false,
      );
      // Score for 3-line clear should comfortably beat 1-line clear.
      expect(svc.score, greaterThan(single.score * 2));
    });

    test('combo resets on a placement that clears nothing', () {
      final svc = ScoreService(_balance);
      svc.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      svc.registerPlacement(
        pieceId: 2,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      expect(svc.combo, 2);
      svc.registerPlacement(
        pieceId: 3,
        type: BlockType.standard,
        cellsPlaced: 3,
        linesCleared: 0,
        boardCleared: false,
      );
      expect(svc.combo, 0);
    });

    test('combo multiplier is capped at comboMultiplierCap', () {
      final svc = ScoreService(_balance);
      for (var i = 0; i < 100; i++) {
        svc.registerPlacement(
          pieceId: i,
          type: BlockType.standard,
          cellsPlaced: 3,
          linesCleared: 1,
          boardCleared: false,
        );
      }
      expect(
        svc.comboMultiplier,
        lessThanOrEqualTo(_balance.economy.comboMultiplierCap),
      );
    });

    test('board-clear placement adds perfect-clear bonus', () {
      final withBoardClear = ScoreService(_balance);
      final without = ScoreService(_balance);
      withBoardClear.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: true,
      );
      without.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      expect(withBoardClear.score, greaterThan(without.score));
    });

    test('coin total tracks per-placement coin deltas', () {
      final svc = ScoreService(_balance);
      svc.registerPlacement(
        pieceId: 1,
        type: BlockType.standard,
        cellsPlaced: 4,
        linesCleared: 1,
        boardCleared: false,
      );
      expect(svc.coinTotal, greaterThan(0));
      expect(svc.coinTotal, svc.records.first.coinDelta);
    });
  });
}
