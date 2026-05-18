import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/department.dart';
import '../../../domain/models/shift_result.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';
import '../../../presentation/widgets/screen_scaffold.dart';
import '../../../services/ads_service.dart';
import '../../../services/analytics_service.dart';

class ShiftResultScreen extends ConsumerStatefulWidget {
  const ShiftResultScreen({required this.result, super.key});
  final ShiftResult result;

  @override
  ConsumerState<ShiftResultScreen> createState() => _ShiftResultScreenState();
}

class _ShiftResultScreenState extends ConsumerState<ShiftResultScreen> {
  bool _doubled = false;
  int _payout = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_settleShift);
  }

  Future<void> _settleShift() async {
    final ref0 = ref;
    final profile = ref0.read(playerProfileProvider);
    final economy = ref0.read(economyServiceProvider);
    final progression = ref0.read(progressionServiceProvider);
    final analytics = ref0.read(analyticsServiceProvider);
    final dailyRepo = ref0.read(dailyRepositoryProvider);

    progression.recordShift(profile, widget.result);
    final payout =
        economy.payoutForShift(profile: profile, result: widget.result);
    economy.award(profile, payout);

    if (widget.result.shiftId.startsWith('daily-')) {
      final dateKey = widget.result.shiftId.replaceFirst('daily-', '');
      final attempt = DailyAttempt(
        dateKey: dateKey,
        score: widget.result.score,
        completed: widget.result.completed,
        attemptedAt: DateTime.now(),
      );
      profile.dailyAttempts.add(attempt);
      final all = await dailyRepo.loadAll();
      all.fold((list) async {
        final updated = [...list, attempt];
        await dailyRepo.saveAll(updated);
      }, (_) {});
    }

    await ref0.read(playerProfileProvider.notifier).persist();

    analytics.logEvent(AnalyticsEvents.shiftEnd, params: {
      'shiftId': widget.result.shiftId,
      'completed': widget.result.completed,
      'score': widget.result.score,
      'payout': payout,
    });

    if (mounted) setState(() => _payout = payout);
  }

  Future<void> _onDouble() async {
    final ads = ref.read(adsServiceProvider);
    final result = await ads.showRewarded(AdPlacement.doubleShiftReward);
    result.fold((outcome) {
      if (outcome is AdRewardGranted) {
        // Grant a second payout of equal size — effectively doubling
        // what was awarded during `_settleShift`.
        ref.read(playerProfileProvider.notifier).mutate((p) {
          p.wallet.add(Currency.coins, _payout);
        });
        ref.read(playerProfileProvider.notifier).persist();
        setState(() {
          _payout *= 2;
          _doubled = true;
        });
      }
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final profile = ref.watch(playerProfileProvider);
    final progression = ref.read(progressionServiceProvider);
    final nextRooms = progression.nextRestorableDepartments(profile);
    final nextRoom = nextRooms.isEmpty ? null : nextRooms.first;
    final coins = profile.wallet.get(Currency.coins);
    return ScreenScaffold(
      title: Strings.gameOverTitle,
      showBack: false,
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCard(label: 'Score', value: '${r.score}'),
              _StatCard(label: Strings.bestScore, value: '${profile.bestShiftScore}'),
              _StatCard(label: Strings.linesCleared, value: '${r.linesCleared}'),
              _StatCard(label: Strings.biggestCombo, value: '${r.maxCombo}'),
              _StatCard(label: 'Pieces placed', value: '${r.piecesPlaced}'),
              const SizedBox(height: 16),
              _StatCard(
                label: Strings.resultPayout,
                value: '$_payout coins',
                highlight: true,
              ),
              _RestorationProgressCard(
                coins: coins,
                nextRoom: nextRoom,
                onTap: () => context.go(AppRoutes.departments),
              ),
              const SizedBox(height: 20),
              if (!_doubled)
                PrimaryButton(
                  label: Strings.resultDouble,
                  icon: Icons.movie,
                  color: AppColors.accentGhost,
                  foreground: AppColors.background,
                  onPressed: _payout > 0 ? _onDouble : null,
                ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: Strings.resultPlayAgain,
                icon: Icons.replay,
                color: AppColors.accentGold,
                foreground: AppColors.background,
                onPressed: () => context.pushReplacement(AppRoutes.brief),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: Strings.resultRestoreOffice,
                icon: Icons.apartment,
                color: AppColors.surfaceHi,
                foreground: AppColors.textPrimary,
                onPressed: () => context.go(AppRoutes.departments),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Back to menu',
                onPressed: () => context.go(AppRoutes.menu),
              ),
            ],
          ),
        ),
    );
  }
}

class _RestorationProgressCard extends StatelessWidget {
  const _RestorationProgressCard({
    required this.coins,
    required this.nextRoom,
    required this.onTap,
  });

  final int coins;
  final DepartmentDescriptor? nextRoom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final room = nextRoom;
    final progress = room == null
        ? 1.0
        : (coins / room.restoreCost).clamp(0.0, 1.0).toDouble();
    final title = room == null ? 'Office restored' : 'Next room: ${room.name}';
    final subtitle = room == null
        ? 'Every room in Dead Dispatch is restored.'
        : '${unlockSummary(room.unlocks)} - $coins / ${room.restoreCost} coins';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.accentGold.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.apartment,
                  color: AppColors.accentGold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.accentGold,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: AppColors.accentGold,
                backgroundColor: AppColors.surfaceHi,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surfaceHi : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.accentGold : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.accentGold : AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
