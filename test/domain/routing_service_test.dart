import 'package:dead_dispatch/domain/balance/balance_data.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/hazard.dart';
import 'package:dead_dispatch/domain/models/package.dart';
import 'package:dead_dispatch/domain/models/package_type.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:dead_dispatch/domain/services/routing_service.dart';
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
      packages: const {
        PackageType.standard: PackageDescriptor(
          type: PackageType.standard,
          baseScore: 30,
          baseSpeed: 90,
          fragility: 0,
          canStamp: false,
          timedDecay: false,
          lane: 'north',
          colorHex: '#fff',
        ),
        PackageType.priority: PackageDescriptor(
          type: PackageType.priority,
          baseScore: 60,
          baseSpeed: 95,
          fragility: 0,
          canStamp: true,
          timedDecay: false,
          lane: 'vault',
          colorHex: '#fff',
        ),
        PackageType.fragile: PackageDescriptor(
          type: PackageType.fragile,
          baseScore: 75,
          baseSpeed: 70,
          fragility: 0.9,
          canStamp: false,
          timedDecay: false,
          lane: 'south',
          colorHex: '#fff',
        ),
        PackageType.duplicate: PackageDescriptor(
          type: PackageType.duplicate,
          baseScore: 20,
          baseSpeed: 95,
          fragility: 0,
          canStamp: false,
          timedDecay: false,
          lane: 'shred',
          colorHex: '#fff',
        ),
        PackageType.decaying: PackageDescriptor(
          type: PackageType.decaying,
          baseScore: 90,
          baseSpeed: 100,
          fragility: 0.3,
          canStamp: false,
          timedDecay: true,
          lane: 'incinerator',
          colorHex: '#fff',
        ),
      },
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

GamePackage _pkg(PackageType t, {bool stamped = false, double decay = 0}) =>
    GamePackage(
      id: 1,
      type: t,
      spawnedAt: Duration.zero,
      stamped: stamped,
      decayProgress: decay,
    );

void main() {
  final routing = RoutingService(_balance());

  test('standard mail in correct lane → perfect', () {
    expect(
      routing.resolve(
          package: _pkg(PackageType.standard), actualLane: 'north'),
      SortOutcome.perfect,
    );
  });

  test('standard mail in wrong lane → miss', () {
    expect(
      routing.resolve(
          package: _pkg(PackageType.standard), actualLane: 'vault'),
      SortOutcome.miss,
    );
  });

  test('priority without stamp in correct lane → acceptable', () {
    expect(
      routing.resolve(
          package: _pkg(PackageType.priority), actualLane: 'vault'),
      SortOutcome.acceptable,
    );
  });

  test('priority with stamp in correct lane → perfect', () {
    expect(
      routing.resolve(
        package: _pkg(PackageType.priority, stamped: true),
        actualLane: 'vault',
      ),
      SortOutcome.perfect,
    );
  });

  test('fragile in wrong lane is destroyed', () {
    expect(
      routing.resolve(
          package: _pkg(PackageType.fragile), actualLane: 'north'),
      SortOutcome.destroyed,
    );
  });

  test('duplicate belongs in shred', () {
    expect(
      routing.resolve(
          package: _pkg(PackageType.duplicate), actualLane: 'shred'),
      SortOutcome.perfect,
    );
    expect(
      routing.resolve(
          package: _pkg(PackageType.duplicate), actualLane: 'north'),
      SortOutcome.miss,
    );
  });

  test('over-decayed mail is destroyed regardless of lane', () {
    expect(
      routing.resolve(
        package: _pkg(PackageType.decaying, decay: 0.99),
        actualLane: 'incinerator',
      ),
      SortOutcome.destroyed,
    );
  });
}
