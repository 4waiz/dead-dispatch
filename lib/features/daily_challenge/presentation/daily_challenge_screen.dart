import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/services/daily_seed.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';
import '../../../presentation/widgets/screen_scaffold.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = DailySeed.todayKey();
    final repo = ref.read(dailyRepositoryProvider);
    final profile = ref.watch(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    final dailyCfg = difficulty.buildDaily(profile, dateKey: dateKey);
    final modifier = dailyCfg.dailyModifier;

    return ScreenScaffold(
      title: Strings.dailyTitle,
      body: FutureBuilder(
        future: repo.latestFor(dateKey),
        builder: (ctx, snap) {
          DailyAttempt? best;
          if (snap.hasData) {
            best = snap.data!.fold<DailyAttempt?>(
              (attempt) => attempt,
              (_) => null,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateKey,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seeded shift with a special modifier. '
                      'Same rules for every player today.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    if (modifier != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.accentGhost.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentGhost
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          dailyModifierLabel(modifier).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accentGhost,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dailyModifierHint(modifier),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (best != null)
                      Text(
                        'Best today · ${best.score}'
                        '${best.completed ? " · cleared" : ""}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                        ),
                      )
                    else
                      const Text(
                        'No attempts yet today.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Attempt today',
                onPressed: () =>
                    context.push('${AppRoutes.game}?daily=$dateKey'),
              ),
            ],
          );
        },
      ),
    );
  }
}
