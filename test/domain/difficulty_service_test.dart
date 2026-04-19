import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/package_type.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/difficulty_service.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceData _balance() => BalanceData(
      shifts: const ShiftBalance(
        baseDuration: Duration(seconds: 75),
        baseSpawnInterval: Duration(milliseconds: 1800),
        minSpawnInterval: Duration(milliseconds: 500),
        spawnIntervalDecayPerLevel: Duration(milliseconds: 60),
        baseTargetScore: 600,
        targetScoreGrowth: 1.18,
        unlockOrder: [
          PackageType.standard,
          PackageType.priority,
          PackageType.fragile,
          PackageType.frozen,
        ],
        maxConcurrentBase: 4,
        maxConcurrentGrowthEvery: 3,
      ),
      packages: const <PackageType, PackageDescriptor>{},
      hazards: const <HazardKind, HazardDescriptor>{},
      upgrades: const <UpgradeKind, UpgradeDescriptor>{},
      departments: const <DepartmentDescriptor>[],
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
  group('DifficultyService', () {
    test('early shifts have smaller allowed-type pool', () {
      final svc = DifficultyService(_balance());
      final profile = PlayerProfile.fresh(1);
      final cfg = svc.buildRegular(profile);
      expect(cfg.allowedTypes.length, lessThanOrEqualTo(3));
    });

    test('progressionLevel increases with totalShiftsPlayed', () {
      final svc = DifficultyService(_balance());
      final profile = PlayerProfile.fresh(1);
      final early = svc.progressionLevelFor(profile);
      profile.totalShiftsPlayed = 15;
      final later = svc.progressionLevelFor(profile);
      expect(later, greaterThan(early));
    });

    test('target score grows with level', () {
      final svc = DifficultyService(_balance());
      final profile = PlayerProfile.fresh(1);
      final base = svc.buildRegular(profile).targetScore;
      profile.totalShiftsPlayed = 20;
      final harder = svc.buildRegular(profile).targetScore;
      expect(harder, greaterThan(base));
    });

    test('daily challenge is deterministic for a date', () {
      final svc = DifficultyService(_balance());
      final profile = PlayerProfile.fresh(1);
      final a = svc.buildDaily(profile, dateKey: '2026-04-19');
      final b = svc.buildDaily(profile, dateKey: '2026-04-19');
      expect(a.seed, b.seed);
      expect(a.modifiers, b.modifiers);
    });

    test('different daily dates → different seeds', () {
      final svc = DifficultyService(_balance());
      final profile = PlayerProfile.fresh(1);
      final a = svc.buildDaily(profile, dateKey: '2026-04-19');
      final b = svc.buildDaily(profile, dateKey: '2026-04-20');
      expect(a.seed, isNot(b.seed));
    });
  });
}
