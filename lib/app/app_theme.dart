import 'package:flutter/material.dart';

import '../presentation/theme/colors.dart';

/// Single source of truth for ThemeData. Dark by default — the haunted
/// office tone calls for it. Light mode would be a future cosmetic unlock.
class AppTheme {
  const AppTheme._();

  static ThemeData dark({bool largeText = false}) {
    final base = ThemeData.dark(useMaterial3: true);
    final scale = largeText ? 1.20 : 1.0;
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surface,
        primary: AppColors.accentGold,
        secondary: AppColors.accentGhost,
        error: AppColors.accentDanger,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            fontSizeFactor: scale,
          )
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 26 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
