import 'package:flutter/material.dart';

import '../../l10n/strings_en.dart';
import '../theme/colors.dart';
import 'primary_button.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({
    required this.onResume,
    required this.onQuit,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: Strings.shiftResume, onPressed: onResume),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onQuit,
              child: const Text(Strings.menuQuit,
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
