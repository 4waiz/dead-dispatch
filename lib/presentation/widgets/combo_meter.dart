import 'package:flutter/material.dart';

import '../theme/colors.dart';

class ComboMeter extends StatelessWidget {
  const ComboMeter({required this.combo, required this.multiplier, super.key});
  final int combo;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final showing = combo > 0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: showing ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showing ? AppColors.accentGold : AppColors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: AppColors.accentGold, size: 18),
            const SizedBox(width: 6),
            Text(
              'x${multiplier.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$combo',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
