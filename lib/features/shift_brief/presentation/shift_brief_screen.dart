import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../domain/balance/balance_data.dart';
import '../../../domain/models/hazard.dart';
import '../../../domain/models/package_type.dart';
import '../../../domain/models/shift_config.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';

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
    final level = difficulty.progressionLevelFor(profile);
    final balance = ref.watch(balanceDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BriefBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(cfg, level),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _buildStatRow(cfg),
                        const SizedBox(height: 16),
                        _buildParcelsCard(cfg, balance),
                        if (cfg.allowedHazards.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildHazardsCard(cfg),
                        ],
                        if (cfg.modifiers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildModifiersCard(cfg),
                        ],
                        const SizedBox(height: 24),
                        _BeginButton(
                          onPressed: () {
                            final route = dailyDateKey != null
                                ? '${AppRoutes.game}?daily=$dailyDateKey'
                                : AppRoutes.game;
                            context.pushReplacement(route);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ShiftConfig cfg, int level) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.accentGold,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            cfg.isDaily ? 'DAILY BRIEF' : 'SHIFT BRIEF',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sort parcels, hit the target, earn coins, restore the office.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              'CLEARANCE LEVEL $level',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(ShiftConfig cfg) {
    final secsLeft = cfg.duration.inSeconds;
    final mins = secsLeft ~/ 60;
    final secs = secsLeft % 60;
    final timeStr =
        mins > 0 ? '$mins:${secs.toString().padLeft(2, '0')}' : '${secsLeft}s';

    final speedPct =
        ((cfg.beltSpeedMultiplier - 1.0) * 100).round().clamp(0, 200);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.emoji_events,
            label: 'TARGET',
            value: '${cfg.targetScore}',
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.timer,
            label: 'DURATION',
            value: timeStr,
            color: AppColors.accentGhost,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.speed,
            label: 'BELT SPEED',
            value: '+$speedPct%',
            color: speedPct >= 20 ? AppColors.accentDanger : AppColors.accentOk,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelsCard(ShiftConfig cfg, BalanceData balance) {
    return _SectionCard(
      title: 'WHAT TO SORT',
      accentColor: AppColors.accentGold,
      icon: Icons.inventory_2,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cfg.allowedTypes
            .map((t) => _ParcelChip(type: t, balance: balance))
            .toList(),
      ),
    );
  }

  Widget _buildHazardsCard(ShiftConfig cfg) {
    return _SectionCard(
      title: 'ACTIVE HAZARDS',
      accentColor: AppColors.accentDanger,
      icon: Icons.warning_amber,
      child: Column(
        children: cfg.allowedHazards.map((h) => _HazardRow(kind: h)).toList(),
      ),
    );
  }

  Widget _buildModifiersCard(ShiftConfig cfg) {
    return _SectionCard(
      title: 'SHIFT MODIFIERS',
      accentColor: AppColors.accentGhost,
      icon: Icons.auto_awesome,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cfg.modifiers
            .map(
              (m) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGhost.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentGhost.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  m.key.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accentGhost,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _BriefBg extends StatelessWidget {
  const _BriefBg();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BgPainter());
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x05F5C04A)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 32) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    final glowRect =
        Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x14F5C04A), Color(0x00F5C04A)],
        ).createShader(glowRect),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.child,
  });
  final String title;
  final Color accentColor;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ParcelChip extends StatelessWidget {
  const _ParcelChip({required this.type, required this.balance});
  final PackageType type;
  final BalanceData balance;

  IconData get _icon {
    switch (type) {
      case PackageType.standard:
        return Icons.inventory_2;
      case PackageType.priority:
        return Icons.bolt;
      case PackageType.fragile:
        return Icons.warning_amber;
      case PackageType.frozen:
        return Icons.ac_unit;
      case PackageType.ghost:
        return Icons.auto_awesome;
      case PackageType.mislabeled:
        return Icons.help_outline;
      case PackageType.duplicate:
        return Icons.content_cut;
      case PackageType.decaying:
        return Icons.local_fire_department;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = AppColors.forPackage(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: col, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                packageDisplayName(type).toUpperCase(),
                style: TextStyle(
                  color: col,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                briefRuleFor(type, balance),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HazardRow extends StatelessWidget {
  const _HazardRow({required this.kind});
  final HazardKind kind;

  IconData get _icon {
    switch (kind) {
      case HazardKind.beltJam:
        return Icons.block;
      case HazardKind.misrouteChain:
        return Icons.shuffle;
      case HazardKind.surgeRush:
        return Icons.bolt;
      case HazardKind.powerFlicker:
        return Icons.flash_off;
      case HazardKind.vipWave:
        return Icons.star;
      case HazardKind.blackout:
        return Icons.visibility_off;
    }
  }

  String get _desc {
    switch (kind) {
      case HazardKind.beltJam:
        return 'Belt stops — parcels pile up';
      case HazardKind.misrouteChain:
        return 'Lane labels randomly swap';
      case HazardKind.surgeRush:
        return 'Double spawn rate for a burst';
      case HazardKind.powerFlicker:
        return 'Screen flickers, lanes go dark';
      case HazardKind.vipWave:
        return 'Only priority & ghost parcels';
      case HazardKind.blackout:
        return 'Full blackout — route by memory';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentDanger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: AppColors.accentDanger, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.key.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _desc,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginButton extends StatelessWidget {
  const _BeginButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5C04A), Color(0xFFE8A020)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55F5C04A),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF161824),
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'BEGIN SHIFT',
              style: TextStyle(
                color: Color(0xFF161824),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
