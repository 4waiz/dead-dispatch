import 'package:flutter/material.dart';

import '../../../../presentation/theme/colors.dart';
import '../../game/session/puzzle_events.dart';

/// Two-button row above the tray for the v1-active power-ups
/// (Stamp Blast and Ghost Swap). Return Sender + Lantern Sweep show as
/// disabled chips so players can see what's coming.
class PowerUpDock extends StatelessWidget {
  const PowerUpDock({
    required this.stampBlastCharges,
    required this.ghostSwapCharges,
    required this.onStampBlast,
    required this.onGhostSwap,
    required this.armedPowerUp,
    super.key,
  });

  final int stampBlastCharges;
  final int ghostSwapCharges;
  final VoidCallback onStampBlast;
  final VoidCallback onGhostSwap;

  /// Which power-up is currently armed (next board tap activates it).
  /// Highlights the active button.
  final PowerUpId? armedPowerUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PowerButton(
            icon: Icons.approval,
            label: 'Stamp Blast',
            charges: stampBlastCharges,
            armed: armedPowerUp == PowerUpId.stampBlast,
            color: AppColors.accentGold,
            onTap: stampBlastCharges > 0 ? onStampBlast : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PowerButton(
            icon: Icons.shuffle,
            label: 'Ghost Swap',
            charges: ghostSwapCharges,
            armed: armedPowerUp == PowerUpId.ghostSwap,
            color: AppColors.accentGhost,
            onTap: ghostSwapCharges > 0 ? onGhostSwap : null,
          ),
        ),
      ],
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.icon,
    required this.label,
    required this.charges,
    required this.armed,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int charges;
  final bool armed;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: armed
              ? color.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: armed ? 1.0 : 0.45)
                : AppColors.outline,
            width: armed ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: enabled ? color : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: enabled
                    ? color.withValues(alpha: 0.18)
                    : AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$charges',
                style: TextStyle(
                  color: enabled ? color : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
