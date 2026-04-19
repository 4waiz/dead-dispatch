import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/shift_result.dart';
import '../../../l10n/strings_en.dart';
import '../../../services/ads_service.dart';
import '../../../services/analytics_service.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';
import '../../../presentation/widgets/reward_dialog.dart';

class ShiftResultScreen extends ConsumerStatefulWidget {
  const ShiftResultScreen({required this.result, super.key});
  final ShiftResult result;

  @override
  ConsumerState<ShiftResultScreen> createState() => _ShiftResultScreenState();
}

class _ShiftResultScreenState extends ConsumerState<ShiftResultScreen> {
  bool _doubled = false;
  bool _mysteryClaimed = false;
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
    final payout = economy.payoutForShift(profile: profile, result: widget.result);
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

  Future<void> _onMystery() async {
    final ads = ref.read(adsServiceProvider);
    final economy = ref.read(economyServiceProvider);
    final result = await ads.showRewarded(AdPlacement.mysteryParcel);
    result.fold((outcome) {
      if (outcome is AdRewardGranted) {
        final reward = economy.rollMysteryParcelReward();
        ref.read(playerProfileProvider.notifier).mutate((p) {
          economy.award(p, reward);
        });
        ref.read(playerProfileProvider.notifier).persist();
        setState(() => _mysteryClaimed = true);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => RewardDialog(
            title: 'Mystery parcel',
            body: 'You found $reward coins inside!',
            confirmLabel: 'Nice',
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(Strings.shiftEnd)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCard(label: 'Score', value: '${r.score}'),
              _StatCard(label: 'Max combo', value: '${r.maxCombo}'),
              _StatCard(label: 'Perfect', value: '${r.perfects}'),
              _StatCard(label: 'Misses', value: '${r.misses}'),
              _StatCard(label: 'Destroyed', value: '${r.destroyed}'),
              const SizedBox(height: 16),
              _StatCard(
                label: Strings.resultPayout,
                value: '$_payout coins',
                highlight: true,
              ),
              const Spacer(),
              if (!_doubled)
                PrimaryButton(
                  label: Strings.resultDouble,
                  icon: Icons.movie,
                  color: AppColors.accentGhost,
                  foreground: AppColors.background,
                  onPressed: _payout > 0 ? _onDouble : null,
                ),
              const SizedBox(height: 8),
              if (!_mysteryClaimed)
                PrimaryButton(
                  label: Strings.resultMystery,
                  icon: Icons.card_giftcard,
                  color: AppColors.surfaceHi,
                  foreground: AppColors.textPrimary,
                  onPressed: _onMystery,
                ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Continue',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
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
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          Text(value,
              style: TextStyle(
                color: highlight ? AppColors.accentGold : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
