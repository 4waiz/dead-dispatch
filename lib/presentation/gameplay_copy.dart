import '../domain/balance/balance_data.dart';
import '../domain/models/department.dart';
import '../domain/models/package_type.dart';

String packageDisplayName(PackageType type) {
  switch (type) {
    case PackageType.standard:
      return 'Standard Parcel';
    case PackageType.priority:
      return 'Priority Parcel';
    case PackageType.fragile:
      return 'Fragile Parcel';
    case PackageType.frozen:
      return 'Frozen Parcel';
    case PackageType.ghost:
      return 'Ghost Parcel';
    case PackageType.mislabeled:
      return 'Mislabeled Parcel';
    case PackageType.duplicate:
      return 'Duplicate Parcel';
    case PackageType.decaying:
      return 'Decaying Parcel';
  }
}

String laneDisplayName(String lane) {
  switch (lane) {
    case 'north':
      return 'Mail Bay';
    case 'vault':
      return 'Secure Vault';
    case 'south':
      return 'Side Chute';
    case 'cold':
      return 'Freezer';
    case 'void':
      return 'Void Gate';
    case 'review':
      return 'Review Desk';
    case 'shred':
      return 'Shredder';
    case 'incinerator':
      return 'Incinerator';
    default:
      return lane
          .split('_')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
  }
}

String destinationForType(PackageType type, BalanceData balance) {
  return laneDisplayName(balance.packageOf(type).lane);
}

String routingInstructionFor({
  required PackageType type,
  required BalanceData balance,
  required bool stamped,
}) {
  final destination = destinationForType(type, balance);
  switch (type) {
    case PackageType.priority:
      return stamped
          ? 'Stamped. Send it to $destination.'
          : 'Stamp it, then send it to $destination.';
    case PackageType.fragile:
      return 'Send it to $destination. Wrong lanes break it.';
    case PackageType.frozen:
      return 'Send it to $destination before it decays.';
    case PackageType.mislabeled:
      return 'Send it to $destination for inspection.';
    case PackageType.duplicate:
      return 'Send duplicate mail to $destination.';
    case PackageType.decaying:
      return 'Burn it in the $destination before it rots.';
    case PackageType.ghost:
      return stamped
          ? 'Stamped. Send it through the $destination.'
          : 'Stamp it, then send it through the $destination.';
    case PackageType.standard:
      return 'Send it to $destination.';
  }
}

String briefRuleFor(PackageType type, BalanceData balance) {
  final destination = destinationForType(type, balance);
  switch (type) {
    case PackageType.priority:
      return 'Stamp, then $destination';
    case PackageType.fragile:
      return 'Route to $destination';
    case PackageType.frozen:
      return 'Route before decay';
    case PackageType.mislabeled:
      return 'Route to $destination';
    case PackageType.duplicate:
      return 'Destroy in $destination';
    case PackageType.decaying:
      return 'Burn in $destination';
    case PackageType.ghost:
      return 'Stamp, then $destination';
    case PackageType.standard:
      return 'Route to $destination';
  }
}

String unlockSummary(DepartmentUnlock unlocks) {
  if (unlocks.packageType != null) {
    return 'Unlocks ${_titleCase(unlocks.packageType!)} parcels';
  }
  if (unlocks.upgradeKind != null) {
    return 'Unlocks ${_titleCase(unlocks.upgradeKind!)} upgrades';
  }
  if (unlocks.modifier != null) {
    return 'Unlocks ${_titleCase(unlocks.modifier!)} modifier';
  }
  if (unlocks.hazard != null) {
    return 'Unlocks ${_titleCase(unlocks.hazard!)} hazard';
  }
  if (unlocks.cosmetic != null) {
    return 'Restores ${_titleCase(unlocks.cosmetic!)}';
  }
  return 'Restores part of the office';
}

String _titleCase(String value) {
  return value
      .split(RegExp('[_\\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
