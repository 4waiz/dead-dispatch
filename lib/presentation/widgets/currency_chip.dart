import 'package:flutter/material.dart';

import '../theme/colors.dart';

class CurrencyChip extends StatelessWidget {
  const CurrencyChip({required this.amount, this.icon, super.key});

  final int amount;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.toll, color: AppColors.accentGold, size: 18),
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
