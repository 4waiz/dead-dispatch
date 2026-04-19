import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug_flags.dart';
import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/currency_chip.dart';
import '../../../presentation/widgets/primary_button.dart';

/// First screen the player sees after splash. Hosts the entire navigation
/// tree of the meta-game (play, daily, upgrades, departments, settings).
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    Strings.appTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  CurrencyChip(amount: profile.wallet.get(Currency.coins)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Best score · ${profile.bestShiftScore} · '
                'Shifts · ${profile.totalShiftsPlayed}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              PrimaryButton(
                label: profile.tutorialCompleted
                    ? Strings.menuPlay
                    : Strings.menuTutorial,
                onPressed: () => Navigator.of(context).pushNamed(
                    profile.tutorialCompleted ? '/game' : '/tutorial'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: Strings.menuDaily,
                color: AppColors.accentGhost,
                foreground: AppColors.background,
                icon: Icons.calendar_today,
                onPressed: () => Navigator.of(context).pushNamed('/daily'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: Strings.menuUpgrades,
                color: AppColors.surfaceHi,
                foreground: AppColors.textPrimary,
                icon: Icons.bolt,
                onPressed: () => Navigator.of(context).pushNamed('/upgrades'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: Strings.menuDepartments,
                color: AppColors.surfaceHi,
                foreground: AppColors.textPrimary,
                icon: Icons.apartment,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/departments'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: Strings.menuSettings,
                      color: AppColors.surface,
                      foreground: AppColors.textPrimary,
                      icon: Icons.settings,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/settings'),
                    ),
                  ),
                  if (DebugFlags.cheatsEnabled) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Debug',
                        color: AppColors.accentDanger,
                        foreground: AppColors.background,
                        icon: Icons.bug_report,
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/debug'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
