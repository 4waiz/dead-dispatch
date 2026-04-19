import '../models/department.dart';
import '../models/hazard.dart';
import '../models/package_type.dart';
import '../models/upgrade.dart';
import 'balance_data.dart';

/// Pure assembler — feed it parsed JSON maps, get back [BalanceData].
/// Stays in domain so nothing here imports `dart:io` or `rootBundle`.
class BalanceProvider {
  const BalanceProvider();

  BalanceData assemble({
    required Map<String, Object?> balanceJson,
    required List<Map<String, Object?>> packagesJson,
    required List<Map<String, Object?>> hazardsJson,
    required List<Map<String, Object?>> upgradesJson,
    required List<Map<String, Object?>> departmentsJson,
  }) {
    final packages = <PackageType, PackageDescriptor>{};
    for (final raw in packagesJson) {
      final desc = PackageDescriptor.fromJson(raw);
      packages[desc.type] = desc;
    }
    final hazards = <HazardKind, HazardDescriptor>{};
    for (final raw in hazardsJson) {
      final desc = HazardDescriptor.fromJson(raw);
      hazards[desc.kind] = desc;
    }
    final upgrades = <UpgradeKind, UpgradeDescriptor>{};
    for (final raw in upgradesJson) {
      final desc = UpgradeDescriptor.fromJson(raw);
      upgrades[desc.kind] = desc;
    }
    final departments = departmentsJson
        .map(DepartmentDescriptor.fromJson)
        .toList(growable: false);

    return BalanceData(
      shifts: ShiftBalance.fromJson(
          balanceJson['shifts']! as Map<String, Object?>),
      packages: packages,
      hazards: hazards,
      upgrades: upgrades,
      departments: departments,
      economy: EconomyBalance.fromJson(
          balanceJson['economy']! as Map<String, Object?>),
    );
  }
}
