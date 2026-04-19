import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';

/// Pre-shift briefing. Shows the target score, duration, active modifiers,
/// and any hazards the player can expect. Gives the player a beat to
/// mentally prepare before the belt starts moving.
class ShiftBriefScreen extends ConsumerWidget {
  const ShiftBriefScreen({this.dailyDateKey, super.key});
  final String? dailyDateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    final cfg = dailyDateKey != null
        ? difficulty.buildDaily(profile, dateKey: dailyDateKey)
        : difficulty.buildRegular(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(cfg.isDaily ? 'Daily brief' : 'Shift brief'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BriefTile(label: 'Target score', value: '${cfg.targetScore}'),
              _BriefTile(
                label: 'Duration',
                value: '${cfg.duration.inSeconds}s',
              ),
              _BriefTile(
                label: 'Allowed parcels',
                value: cfg.allowedTypes.map((t) => t.key).join(', '),
              ),
              if (cfg.allowedHazards.isNotEmpty)
                _BriefTile(
                  label: 'Hazards in rotation',
                  value: cfg.allowedHazards.map((h) => h.key).join(', '),
                ),
              if (cfg.modifiers.isNotEmpty)
                _BriefTile(
                  label: 'Modifiers',
                  value: cfg.modifiers.map((m) => m.key).join(', '),
                  highlight: true,
                ),
              const Spacer(),
              PrimaryButton(
                label: 'Start shift',
                icon: Icons.play_arrow,
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed('/game', arguments: dailyDateKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefTile extends StatelessWidget {
  const _BriefTile({
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surfaceHi : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.accentGold : AppColors.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    highlight ? AppColors.accentGold : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
