import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/block_type.dart';
import 'package:dead_dispatch/domain/models/currency.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/economy_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _payoutDesc = UpgradeDescriptor(
  kind: UpgradeKind.payoutMultiplier,
  maxLevel: 2,
  title: 'Test',
  description: '',
  costsByLevel: [100, 200],
  effectPerLevel: [0.1, 0.2],
  currency: Currency.coins,
);

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
  blocks: <BlockType, BlockDescriptor>{},
  hazards: <HazardKind, HazardDescriptor>{},
  upgrades: <UpgradeKind, UpgradeDescriptor>{
    UpgradeKind.payoutMultiplier: _payoutDesc,
  },
  departments: [
    DepartmentDescriptor(
      id: 'lobby',
      floor: 1,
      name: 'Lobby',
      flavor: '',
      restoreCost: 250,
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

/// Fresh profile with mutable lists so the economy service can add
/// upgrades and restored departments. Mirrors `PlayerProfile.fresh` but
/// substitutes growable lists.
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
  group('EconomyService', () {
    late EconomyService svc;
    late PlayerProfile profile;

    setUp(() {
      svc = const EconomyService(_balance);
      profile = _freshProfile();
    });

    test('purchaseUpgrade succeeds when enough coins', () {
      profile.wallet.add(Currency.coins, 500);
      final ok =
          svc.purchaseUpgrade(profile, kind: UpgradeKind.payoutMultiplier);
      expect(ok, isTrue);
      expect(profile.upgradeLevel(UpgradeKind.payoutMultiplier), 1);
      expect(profile.wallet.get(Currency.coins), 400);
    });

    test('purchaseUpgrade fails when insufficient funds', () {
      final ok =
          svc.purchaseUpgrade(profile, kind: UpgradeKind.payoutMultiplier);
      expect(ok, isFalse);
      expect(profile.upgradeLevel(UpgradeKind.payoutMultiplier), 0);
    });

    test('purchaseUpgrade fails at max level', () {
      profile.wallet.add(Currency.coins, 10000);
      svc.purchaseUpgrade(profile, kind: UpgradeKind.payoutMultiplier);
      svc.purchaseUpgrade(profile, kind: UpgradeKind.payoutMultiplier);
      final third =
          svc.purchaseUpgrade(profile, kind: UpgradeKind.payoutMultiplier);
      expect(third, isFalse);
    });

    test('restoreDepartment is idempotent', () {
      profile.wallet.add(Currency.coins, 500);
      expect(svc.restoreDepartment(profile, departmentId: 'lobby'), isTrue);
      expect(svc.restoreDepartment(profile, departmentId: 'lobby'), isFalse);
    });

    test('mystery parcel reward stays in balance range', () {
      for (var i = 0; i < 50; i++) {
        final r = svc.rollMysteryParcelReward(seed: i + 1);
        expect(r, greaterThanOrEqualTo(10));
        expect(r, lessThanOrEqualTo(30));
      }
    });
  });
}
