import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../domain/models/block_type.dart';
import '../../../domain/models/hazard.dart';
import '../../../domain/models/shift_config.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';

/// Pre-shift "Ready?" panel. Slim and information-dense: the target
/// score, the blocks you'll see today, and (for Daily Seal) the active
/// modifier. The richer per-piece tutorial lives in the Tutorial screen.
class ShiftBriefScreen extends ConsumerWidget {
  const ShiftBriefScreen({this.dailyDateKey, super.key});
  final String? dailyDateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    final cfg = dailyDateKey != null
        ? difficulty.buildDaily(profile, dateKey: dailyDateKey)
        : difficulty.buildClassic(profile);
    final level = difficulty.progressionLevelFor(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BriefBg(),
          SafeArea(
            child: Column(
              children: [
                _Header(cfg: cfg, level: level),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _StatRow(cfg: cfg),
                        const SizedBox(height: 16),
                        _BlocksCard(cfg: cfg),
                        if (cfg.dailyModifier != null) ...[
                          const SizedBox(height: 12),
                          _ModifierCard(kind: cfg.dailyModifier!),
                        ],
                        const SizedBox(height: 24),
                        _BeginButton(
                          isDaily: cfg.isDaily,
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
}

class _Header extends StatelessWidget {
  const _Header({required this.cfg, required this.level});
  final ShiftConfig cfg;
  final int level;

  @override
  Widget build(BuildContext context) {
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
            child: Icon(
              cfg.isDaily ? Icons.local_post_office : Icons.dashboard_customize,
              color: AppColors.accentGold,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            cfg.isDaily ? 'DAILY SEAL' : 'CLASSIC SHIFT',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drop ghost-mail blocks onto the desk. Fill rows or columns '
            'to clear them and earn coins.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
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
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.cfg});
  final ShiftConfig cfg;

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.grid_on,
            label: 'BOARD',
            value: '${cfg.gridSize}×${cfg.gridSize}',
            color: AppColors.accentGhost,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.view_module,
            label: 'PIECES',
            value: '${cfg.pieceQueueSize}',
            color: AppColors.accentOk,
          ),
        ),
      ],
    );
  }
}

class _BlocksCard extends StatelessWidget {
  const _BlocksCard({required this.cfg});
  final ShiftConfig cfg;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "TONIGHT'S MAIL",
      accentColor: AppColors.accentGold,
      icon: Icons.mail_outline,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            cfg.allowedTypes.map((t) => _BlockChip(type: t)).toList(),
      ),
    );
  }
}

class _ModifierCard extends StatelessWidget {
  const _ModifierCard({required this.kind});
  final HazardKind kind;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'DAILY MODIFIER',
      accentColor: AppColors.accentGhost,
      icon: Icons.auto_awesome,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGhost.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGhost.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              dailyModifierLabel(kind).toUpperCase(),
              style: const TextStyle(
                color: AppColors.accentGhost,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dailyModifierHint(kind),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
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
    final glowRect = Rect.fromLTWH(
      0,
      size.height * 0.7,
      size.width,
      size.height * 0.3,
    );
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

class _BlockChip extends StatelessWidget {
  const _BlockChip({required this.type});
  final BlockType type;

  @override
  Widget build(BuildContext context) {
    final col = AppColors.forBlock(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: col,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            blockDisplayName(type).toUpperCase(),
            style: TextStyle(
              color: col,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginButton extends StatelessWidget {
  const _BeginButton({required this.onPressed, required this.isDaily});
  final VoidCallback onPressed;
  final bool isDaily;

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF161824),
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isDaily ? 'PLAY DAILY SEAL' : 'PLAY SHIFT',
              style: const TextStyle(
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
