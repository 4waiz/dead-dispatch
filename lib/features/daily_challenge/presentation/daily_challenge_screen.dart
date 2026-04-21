import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

import '../../../di/providers.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/services/daily_seed.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = DailySeed.todayKey();
    final repo = ref.read(dailyRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(Strings.dailyTitle)),
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
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seeded shift with a special modifier. '
                          'Same rules for every player today.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
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
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Attempt today',
                  onPressed: () =>
                    context.push('${AppRoutes.game}?daily=$dateKey'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
