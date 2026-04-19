import 'package:flutter/material.dart';

import '../theme/colors.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    required this.message,
    required this.onAdvance,
    super.key,
  });

  final String message;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: GestureDetector(
        onTap: onAdvance,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHi.withValues(alpha: 0.95),
            border: Border.all(color: AppColors.accentGhost),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.accentGhost),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.touch_app, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
