import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug_flags.dart';
import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/screen_scaffold.dart';

/// Developer-only cheats. Gated behind `kDebugMode` via [DebugFlags] —
/// these call sites compile-out in release builds.
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DebugFlags.cheatsEnabled) {
      return const ScreenScaffold(
        title: 'Debug',
        body: Center(
          child: Text(
            'Debug disabled in release builds',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    final profile = ref.watch(playerProfileProvider);
    return ScreenScaffold(
      title: 'Debug cheats',
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Tile(
            label: 'Grant 10,000 coins',
            onTap: () {
              ref.read(playerProfileProvider.notifier).mutate((p) {
                p.wallet.add(Currency.coins, 10000);
              });
              ref.read(playerProfileProvider.notifier).persist();
            },
          ),
          _Tile(
            label: 'Complete tutorial',
            onTap: () {
              ref.read(playerProfileProvider.notifier).mutate((p) {
                p.tutorialCompleted = true;
              });
              ref.read(playerProfileProvider.notifier).persist();
            },
          ),
          _Tile(
            label: 'Bump totalShiftsPlayed +10 (level up)',
            onTap: () {
              ref.read(playerProfileProvider.notifier).mutate((p) {
                p.totalShiftsPlayed += 10;
              });
              ref.read(playerProfileProvider.notifier).persist();
            },
          ),
          const Divider(color: AppColors.outline),
          Text(
            'Profile JSON preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${profile.toJson()}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label,
            style: const TextStyle(color: AppColors.textPrimary)),
        trailing:
            const Icon(Icons.arrow_forward, color: AppColors.accentGold),
        onTap: onTap,
      ),
    );
  }
}
