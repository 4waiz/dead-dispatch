import '../models/block_type.dart';
import '../models/department.dart';
import '../models/hazard.dart';
import '../models/upgrade.dart';
import 'balance_data.dart';

/// Pure assembler — feed it parsed JSON maps, get back [BalanceData].
/// Stays in domain so nothing here imports `dart:io` or `rootBundle`.
class BalanceProvider {
  const BalanceProvider();

  BalanceData assemble({
    required Map<String, Object?> balanceJson,
    required List<Map<String, Object?>> blocksJson,
    required List<Map<String, Object?>> hazardsJson,
    required List<Map<String, Object?>> upgradesJson,
    required List<Map<String, Object?>> departmentsJson,
  }) {
    final blocks = <BlockType, BlockDescriptor>{};
    for (final raw in blocksJson) {
      final desc = BlockDescriptor.fromJson(raw);
      blocks[desc.type] = desc;
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
        balanceJson['shifts']! as Map<String, Object?>,
      ),
      blocks: blocks,
      hazards: hazards,
      upgrades: upgrades,
      departments: departments,
      economy: EconomyBalance.fromJson(
        balanceJson['economy']! as Map<String, Object?>,
      ),
    );
  }
}
