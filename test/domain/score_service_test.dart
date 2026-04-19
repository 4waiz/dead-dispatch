import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/package.dart';
import 'package:dead_dispatch/domain/models/package_type.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/score_service.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceData _stubBalance() {
  return BalanceData(
    shifts: const ShiftBalance(
      baseDuration: Duration(seconds: 60),
      baseSpawnInterval: Duration(milliseconds: 1500),
      minSpawnInterval: Duration(milliseconds: 500),
      spawnIntervalDecayPerLevel: Duration(milliseconds: 50),
      baseTargetScore: 500,
      targetScoreGrowth: 1.1,
      unlockOrder: [PackageType.standard, PackageType.priority],
      maxConcurrentBase: 3,
      maxConcurrentGrowthEvery: 3,
    ),
    packages: {
      PackageType.standard: const PackageDescriptor(
        type: PackageType.standard,
        baseScore: 40,
        baseSpeed: 90,
        fragility: 0,
        canStamp: false,
        timedDecay: false,
        lane: 'north',
        colorHex: '#ffffff',
      ),
    },
    hazards: const <HazardKind, HazardDescriptor>{},
    upgrades: const <UpgradeKind, UpgradeDescriptor>{},
    departments: const <DepartmentDescriptor>[],
    economy: const EconomyBalance(
      coinPerScorePoint: 0.1,
      perfectBonus: 20,
      comboMultiplierStep: 0.1,
      comboMultiplierCap: 3.0,
      dailyCompletionBonus: 0,
      failureForgivenessRefund: 0,
      mysteryParcelMin: 10,
      mysteryParcelMax: 30,
    ),
  );
}

GamePackage _pkg(int id) => GamePackage(
      id: id,
      type: PackageType.standard,
      spawnedAt: Duration.zero,
    );

void main() {
  group('ScoreService', () {
    test('perfect outcome awards base + bonus, scaled by combo multiplier',
        () {
      final svc = ScoreService(_stubBalance());
      final rec = svc.registerOutcome(
        package: _pkg(1),
        outcome: SortOutcome.perfect,
      );
      // combo=1 after; multiplier was 1.0 at time of registration.
      expect(rec.scoreDelta, 60);
      expect(svc.score, 60);
      expect(svc.combo, 1);
    });

    test('misses reset combo and subtract', () {
      final svc = ScoreService(_stubBalance());
      svc.registerOutcome(
          package: _pkg(1), outcome: SortOutcome.perfect);
      svc.registerOutcome(
          package: _pkg(2), outcome: SortOutcome.perfect);
      expect(svc.combo, 2);
      svc.registerOutcome(package: _pkg(3), outcome: SortOutcome.miss);
      expect(svc.combo, 0);
    });

    test('score cannot go negative', () {
      final svc = ScoreService(_stubBalance());
      svc.registerOutcome(
          package: _pkg(1), outcome: SortOutcome.destroyed);
      expect(svc.score, greaterThanOrEqualTo(0));
    });

    test('combo multiplier is capped', () {
      final svc = ScoreService(_stubBalance());
      for (var i = 0; i < 100; i++) {
        svc.registerOutcome(
          package: _pkg(i),
          outcome: SortOutcome.perfect,
        );
      }
      expect(svc.comboMultiplier, lessThanOrEqualTo(3.0));
    });
  });
}
