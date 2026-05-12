/// All canonical ghost-mail block varieties used in the haunted-mailroom
/// block puzzle. Each maps to a cosmetic colour + display name; gameplay
/// rules (placement, line-clear, scoring) treat all blocks uniformly.
/// Adding a new type:
///   1. Add an enum value here.
///   2. Add a colour in `AppColors.forBlock`.
///   3. Add a balance entry in `assets/config/packages.json`.
enum BlockType {
  standard,
  priority,
  fragile,
  frozen,
  ghost,
  cursed,
  voidMail,
  vault;

  /// Stable string used in JSON / saves. Renaming an enum case must NOT
  /// change this string — bump save schema instead.
  String get key {
    switch (this) {
      case BlockType.voidMail:
        return 'void';
      default:
        return name;
    }
  }

  static BlockType fromKey(String key) {
    if (key == 'void') return BlockType.voidMail;
    return BlockType.values.firstWhere(
      (b) => b.name == key,
      orElse: () => BlockType.standard,
    );
  }

  /// Display name used by HUD / tooltips.
  String get displayName {
    switch (this) {
      case BlockType.standard:
        return 'Standard Mail';
      case BlockType.priority:
        return 'Priority Mail';
      case BlockType.fragile:
        return 'Fragile Mail';
      case BlockType.frozen:
        return 'Frozen Mail';
      case BlockType.cursed:
        return 'Cursed Mail';
      case BlockType.vault:
        return 'Vault Mail';
      case BlockType.voidMail:
        return 'Void Mail';
      case BlockType.ghost:
        return 'Ghost Mail';
    }
  }
}

/// Static cosmetic descriptor loaded from `assets/config/packages.json`.
/// Block-puzzle gameplay reads `baseScore` and `colorHex`; other fields
/// are reserved for future tuning.
class BlockDescriptor {
  const BlockDescriptor({
    required this.type,
    required this.baseScore,
    required this.colorHex,
  });

  final BlockType type;
  final int baseScore;
  final String colorHex;

  factory BlockDescriptor.fromJson(Map<String, Object?> j) => BlockDescriptor(
        type: BlockType.fromKey(j['type']! as String),
        baseScore: (j['baseScore']! as num).toInt(),
        colorHex: j['colorHex']! as String,
      );
}
