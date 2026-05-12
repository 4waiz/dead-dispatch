import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/domain/models/currency.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/shift_result.dart';
import 'package:dead_dispatch/domain/services/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _balance = BalanceData(
  shifts: ShiftBalance(
    gridSize: 8,
    pieceQueueSize: 3,
    baseTargetScore: 500,
    targetScoreGrowth: 1.1,
    unlockOrder: [BlockType.standard],
    classicNoTimer: true,
    dailyDuration: null,
  ),
  blocks: {},
  hazards: {},
  upgrades: {},
  departments: [
    DepartmentDescriptor(
      id: 'lobby',
      floor: 1,
      name: 'Lobby',
      flavor: '',
      restoreCost: 250,
      unlocks: DepartmentUnlock(),
    ),
    DepartmentDescriptor(
      id: 'fragile_room',
      floor: 1,
      name: 'Fragile Wing',
      flavor: '',
      restoreCost: 600,
      unlocks: DepartmentUnlock(),
    ),
  ],
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

ShiftResult _result({int score = 100}) => ShiftResult(
      shiftId: 'test-shift',
      score: score,
      combo: 3,
      maxCombo: 5,
      coins: 10,
      records: const [],
      completed: false,
      failureReason: 'score',
      duration: const Duration(seconds: 30),
    );

/// Creates a fresh profile with a mutable (non-const) list for
/// restoredDepartments so tests can mutate it directly.
PlayerProfile _freshProfile() => PlayerProfile(
      schemaVersion: 1,
      createdAt: DateTime(2025),
      lastPlayedAt: DateTime(2025),
      tutorialCompleted: false,
      totalShiftsPlayed: 0,
      bestShiftScore: 0,
      wallet: Wallet(),
      upgrades: [],
      restoredDepartments: [],
      dailyAttempts: [],
      settings: const SettingsSnapshot(),
    );

void main() {
  group('ProgressionService', () {
    late ProgressionService svc;
    late PlayerProfile profile;

    setUp(() {
      svc = const ProgressionService(_balance);
      profile = _freshProfile();
    });

    test('recordShift increments totalShiftsPlayed', () {
      svc.recordShift(profile, _result());
      expect(profile.totalShiftsPlayed, 1);
      svc.recordShift(profile, _result());
      expect(profile.totalShiftsPlayed, 2);
    });

    test('recordShift updates bestShiftScore only when higher', () {
      svc.recordShift(profile, _result(score: 200));
      expect(profile.bestShiftScore, 200);
      svc.recordShift(profile, _result(score: 100));
      expect(profile.bestShiftScore, 200);
      svc.recordShift(profile, _result(score: 350));
      expect(profile.bestShiftScore, 350);
    });

    test('visibleDepartments returns all departments sorted by floor', () {
      final visible = svc.visibleDepartments(profile);
      expect(visible.length, 2);
      expect(visible.first.floor, lessThanOrEqualTo(visible.last.floor));
    });

    test('nextRestorableDepartments excludes already-restored departments', () {
      profile.restoredDepartments
          .add(RestoredDepartment(id: 'lobby', restoredAt: DateTime(2025)));
      final next = svc.nextRestorableDepartments(profile);
      expect(next.any((d) => d.id == 'lobby'), isFalse);
    });

    test('nextRestorableDepartments returns at most 3 entries', () {
      final next = svc.nextRestorableDepartments(profile);
      expect(next.length, lessThanOrEqualTo(3));
    });
  });
}
