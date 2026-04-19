import 'package:flutter/material.dart';

import '../../domain/models/package_type.dart';

/// Centralised palette. Dark office base with vivid accent slots so
/// package types remain readable on small phone screens.
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
  static const Color accentBelt = Color(0xFF353A55);

  static Color forPackage(PackageType type) {
    switch (type) {
      case PackageType.standard:
        return const Color(0xFFA7B0BD);
      case PackageType.priority:
        return accentGold;
      case PackageType.fragile:
        return const Color(0xFFF08A6E);
      case PackageType.frozen:
        return const Color(0xFF7BD3F6);
      case PackageType.ghost:
        return accentGhost;
      case PackageType.mislabeled:
        return const Color(0xFF9F8AC2);
      case PackageType.duplicate:
        return const Color(0xFF7E8B5A);
      case PackageType.decaying:
        return const Color(0xFF6FBD8E);
    }
  }
}
