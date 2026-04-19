import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Generic centered dialog used for ad-rewards, mystery parcel,
/// and "save your run" continue prompts. Keep visual identity consistent.
class RewardDialog extends StatelessWidget {
  const RewardDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    super.key,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (cancelLabel != null)
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      child: Text(
                        cancelLabel!,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
