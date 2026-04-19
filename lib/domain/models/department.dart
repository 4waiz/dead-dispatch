/// Departments = restoration meta-progression. Each "floor" can host many
/// rooms. Restoring a room unlocks new content (package type, hazard,
/// cosmetic, automation helper, etc.).
class DepartmentDescriptor {
  const DepartmentDescriptor({
    required this.id,
    required this.floor,
    required this.name,
    required this.flavor,
    required this.restoreCost,
    required this.unlocks,
  });

  final String id;
  final int floor;
  final String name;
  final String flavor;
  final int restoreCost;
  final DepartmentUnlock unlocks;

  factory DepartmentDescriptor.fromJson(Map<String, Object?> j) =>
      DepartmentDescriptor(
        id: j['id']! as String,
        floor: (j['floor']! as num).toInt(),
        name: j['name']! as String,
        flavor: j['flavor']! as String,
        restoreCost: (j['restoreCost']! as num).toInt(),
        unlocks: DepartmentUnlock.fromJson(
            j['unlocks']! as Map<String, Object?>),
      );
}

class DepartmentUnlock {
  const DepartmentUnlock({
    this.packageType,
    this.hazard,
    this.cosmetic,
    this.upgradeKind,
    this.modifier,
  });

  final String? packageType;
  final String? hazard;
  final String? cosmetic;
  final String? upgradeKind;
  final String? modifier;

  factory DepartmentUnlock.fromJson(Map<String, Object?> j) =>
      DepartmentUnlock(
        packageType: j['packageType'] as String?,
        hazard: j['hazard'] as String?,
        cosmetic: j['cosmetic'] as String?,
        upgradeKind: j['upgradeKind'] as String?,
        modifier: j['modifier'] as String?,
      );
}

class RestoredDepartment {
  const RestoredDepartment({required this.id, required this.restoredAt});
  final String id;
  final DateTime restoredAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'restoredAt': restoredAt.toIso8601String(),
      };

  factory RestoredDepartment.fromJson(Map<String, Object?> j) =>
      RestoredDepartment(
        id: j['id']! as String,
        restoredAt: DateTime.parse(j['restoredAt']! as String),
      );
}
