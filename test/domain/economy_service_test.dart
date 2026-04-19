import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/currency.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/package_type.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/economy_service.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceData _balance() => BalanceData(
      shifts: const ShiftBalance(
        baseDuration: Duration(seconds: 60),
        baseSpawnInterval: Duration(milliseconds: 1500),
        minSpawnInterval: Duration(milliseconds: 500),
        spawnIntervalDecayPerLevel: Duration(milliseconds: 50),
        baseTargetScore: 500,
        targetScoreGrowth: 1.1,
        unlockOrder: [PackageType.standard],
        maxConcurrentBase: 3,
        maxConcurrentGrowthEvery: 3,
      ),
      packages: const <PackageType, PackageDescriptor>{},
      hazards: const <HazardKind, HazardDescriptor>{},
      upgrades: {
        UpgradeKind.payoutMultiplier: const UpgradeDescriptor(
          kind: UpgradeKind.payoutMultiplier,
          maxLevel: 2,
          title: 'Test',
          description: '',
          costsByLevel: [100, 200],
          effectPerLevel: [0.1, 0.2],
          currency: Currency.coins,
        ),
      },
      departments: const [
        DepartmentDescriptor(
          id: 'lobby',
          floor: 1,
          name: 'Lobby',
          flavor: '',
          restoreCost: 250,
          unlocks: DepartmentUnlock(),
        ),
      ],
      economy: const EconomyBalance(
        coinPerScorePoint: 0.1,
        perfectBonus: 0,
        comboMultiplierStep: 0,
        comboMultiplierCap: 1.0,
        dailyCompletionBonus: 0,
        failureForgivenessRefund: 0,
        mysteryParcelMin: 10,
        mysteryParcelMax: 30,
      ),
    );

void main() {
  group('EconomyService', () {
    late EconomyService svc;
    late PlayerProfile profile;

    setUp(() {
      svc = EconomyService(_balance());
      profile = PlayerProfile.fresh(1);
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
