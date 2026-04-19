import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/upgrade.dart';
import '../../../l10n/strings_en.dart';
import '../../../services/analytics_service.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/currency_chip.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final balance = ref.watch(balanceDataProvider);
    final economy = ref.read(economyServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final items = balance.upgrades.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(Strings.upgradesTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CurrencyChip(amount: profile.wallet.get(Currency.coins)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final desc = items[i];
          final current = profile.upgradeLevel(desc.kind);
          final atCap = current >= desc.maxLevel;
          final cost = atCap ? -1 : desc.costForLevel(current + 1);
          final canAfford = !atCap &&
              cost >= 0 &&
              profile.wallet.canSpend(desc.currency, cost);
          return _UpgradeRow(
            title: desc.title,
            description: desc.description,
            level: current,
            maxLevel: desc.maxLevel,
            cost: cost,
            atCap: atCap,
            canAfford: canAfford,
            onBuy: !canAfford
                ? null
                : () {
                    final ok = economy.purchaseUpgrade(profile, kind: desc.kind);
                    if (ok) {
                      ref.read(playerProfileProvider.notifier)
                          .mutate((_) {});
                      ref.read(playerProfileProvider.notifier).persist();
                      analytics.logEvent(
                        AnalyticsEvents.upgradePurchased,
                        params: {
                          'kind': desc.kind.key,
                          'level': current + 1,
                          'cost': cost,
                        },
                      );
                    }
                  },
          );
        },
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({
    required this.title,
    required this.description,
    required this.level,
    required this.maxLevel,
    required this.cost,
    required this.atCap,
    required this.canAfford,
    required this.onBuy,
  });

  final String title;
  final String description;
  final int level;
  final int maxLevel;
  final int cost;
  final bool atCap;
  final bool canAfford;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  'Level $level / $maxLevel',
                  style: const TextStyle(color: AppColors.accentGold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          atCap
              ? const Chip(
                  label: Text('MAX'),
                  backgroundColor: AppColors.surfaceHi,
                )
              : FilledButton(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        canAfford ? AppColors.accentGold : AppColors.outline,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text('$cost'),
                ),
        ],
      ),
    );
  }
}
