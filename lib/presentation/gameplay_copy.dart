import '../domain/models/block_type.dart';
import '../domain/models/department.dart';
import '../domain/models/hazard.dart';

/// Display name for a block type. Used by the result screen, brief, and
/// any tooltip / unlock summary copy.
String blockDisplayName(BlockType type) => type.displayName;

/// Subtitle for a daily modifier. Mirrors `HazardDescriptor.tutorialHint`
/// but allows local overrides without touching balance JSON.
String dailyModifierHint(HazardKind kind) {
  switch (kind) {
    case HazardKind.frozenFloor:
      return 'Frozen Floor — a few cells start frosted. Clear lines next to them to melt them.';
    case HazardKind.priorityRush:
      return 'Priority Rush — orange Priority pieces score extra coins today.';
    case HazardKind.voidSpots:
      return 'Void Spots — two cells start blocked. Clear lines through them to free them.';
    case HazardKind.goldenMail:
      return 'Golden Mail — every gold Vault piece pays out double coins.';
    case HazardKind.fragileBatch:
      return 'Fragile Batch — more Fragile pieces appear in today\'s bag.';
  }
}

/// Compact 1-line label for a daily modifier (chip / menu badge).
String dailyModifierLabel(HazardKind kind) {
  switch (kind) {
    case HazardKind.frozenFloor:
      return 'Frozen Floor';
    case HazardKind.priorityRush:
      return 'Priority Rush';
    case HazardKind.voidSpots:
      return 'Void Spots';
    case HazardKind.goldenMail:
      return 'Golden Mail';
    case HazardKind.fragileBatch:
      return 'Fragile Batch';
  }
}

/// One-line summary describing what restoring a department unlocks.
/// Field semantics for the block-puzzle:
///   • `packageType` → unlocks a new block type
///   • `modifier`   → unlocks a power-up (e.g. "stampBlast", "ghostSwap")
///   • `cosmetic`   → unlocks a board / piece skin
///   • `upgradeKind` → unlocks an upgrade kind for purchase
String unlockSummary(DepartmentUnlock unlocks) {
  if (unlocks.packageType != null) {
    return 'Unlocks ${_titleCase(unlocks.packageType!)} blocks';
  }
  if (unlocks.modifier != null) {
    return 'Unlocks ${_titleCase(unlocks.modifier!)} power-up';
  }
  if (unlocks.cosmetic != null) {
    return 'Restores ${_titleCase(unlocks.cosmetic!)}';
  }
  if (unlocks.upgradeKind != null) {
    return 'Unlocks ${_titleCase(unlocks.upgradeKind!)} upgrades';
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
