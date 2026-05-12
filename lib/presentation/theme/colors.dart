import 'package:flutter/material.dart';

import '../../domain/models/block_type.dart';

/// Centralised palette. Dark haunted-desk base with vivid accent slots so
/// ghost-mail block types remain readable on small phone screens.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF161824);
  static const Color surface = Color(0xFF1F2233);
  static const Color surfaceHi = Color(0xFF2A2E45);
  static const Color outline = Color(0xFF3A3F58);
  static const Color textPrimary = Color(0xFFEDE7DA);
  static const Color textMuted = Color(0xFF9C95B8);

  static const Color accentGold = Color(0xFFF5C04A);
  static const Color accentGhost = Color(0xFFD7C8FF);
  static const Color accentDanger = Color(0xFFE3573B);
  static const Color accentOk = Color(0xFF6FBD8E);

  // Board surface colours used by the block-puzzle grid.
  static const Color boardBg = Color(0xFF101220);
  static const Color cellEmpty = Color(0xFF1B1E2F);
  static const Color cellInvalid = Color(0xFF4A2630);
  static const Color cellValidPreview = Color(0x559FE7F5); // translucent cyan
  static const Color goldenPop = Color(0xFFFFD371);

  /// Block colour by type. Matches `packages.json` so the bag and the
  /// renderer agree.
  static Color forBlock(BlockType type) {
    switch (type) {
      case BlockType.standard:
        return const Color(0xFFF0E5C8); // cream envelope
      case BlockType.priority:
        return const Color(0xFFF0902B); // orange lightning seal
      case BlockType.frozen:
        return const Color(0xFF6CC9F0); // blue frost
      case BlockType.cursed:
        return const Color(0xFFA87BD8); // purple smoke
      case BlockType.vault:
        return accentGold; // gold coin-sealed
      case BlockType.fragile:
        return const Color(0xFFE7E7F2); // glassy cracked
      case BlockType.voidMail:
        return const Color(0xFF5B3E92); // dark purple star
      case BlockType.ghost:
        return const Color(0xFF9FE7F5); // translucent cyan
    }
  }
}
