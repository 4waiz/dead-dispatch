import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/department.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/currency_chip.dart';
import '../../../presentation/widgets/screen_scaffold.dart';
import '../../../services/analytics_service.dart';

class DepartmentScreen extends ConsumerWidget {
  const DepartmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final progression = ref.read(progressionServiceProvider);
    final economy = ref.read(economyServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final all = progression.visibleDepartments(profile);

    return ScreenScaffold(
      title: Strings.departmentsTitle,
      trailing: CurrencyChip(amount: profile.wallet.get(Currency.coins)),
      padding: EdgeInsets.zero,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: all.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return const _RestorationHeader();
          }
          final dept = all[i - 1];
          final restored = profile.isDepartmentRestored(dept.id);
          final canAfford = !restored &&
              profile.wallet.canSpend(Currency.coins, dept.restoreCost);
          return _DepartmentCard(
            dept: dept,
            restored: restored,
            canAfford: canAfford,
            onRestore: !canAfford
                ? null
                : () {
                    final ok = economy.restoreDepartment(
                      profile,
                      departmentId: dept.id,
                    );
                    if (ok) {
                      ref.read(playerProfileProvider.notifier).mutate((_) {});
                      ref.read(playerProfileProvider.notifier).persist();
                      analytics.logEvent(
                        AnalyticsEvents.departmentRestored,
                        params: {
                          'departmentId': dept.id,
                          'floor': dept.floor,
                          'cost': dept.restoreCost,
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

class _RestorationHeader extends StatelessWidget {
  const _RestorationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.apartment, color: AppColors.accentGold, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Spend shift coins to restore rooms. Each restored room unlocks new block types, skins, or power-ups.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.dept,
    required this.restored,
    required this.canAfford,
    required this.onRestore,
  });

  final DepartmentDescriptor dept;
  final bool restored;
  final bool canAfford;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: restored ? AppColors.surfaceHi : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: restored ? AppColors.accentOk : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Floor ${dept.floor}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dept.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (restored)
                const Icon(Icons.check_circle, color: AppColors.accentOk),
            ],
          ),
          const SizedBox(height: 6),
          Text(dept.flavor, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(
            unlockSummary(dept.unlocks),
            style: const TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.toll, color: AppColors.accentGold, size: 18),
              const SizedBox(width: 6),
              Text(
                '${dept.restoreCost}',
                style: const TextStyle(color: AppColors.accentGold),
              ),
              const Spacer(),
              if (!restored)
                FilledButton(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        canAfford ? AppColors.accentGold : AppColors.outline,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Restore room'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
