import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/debug_flags.dart';
import '../../../di/providers.dart';
import '../../../domain/models/currency.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final coins = profile.wallet.get(Currency.coins);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Atmospheric background stripes
          const _BackgroundDecoration(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // ── Branding ────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentGold.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_post_office,
                            color: AppColors.accentGold,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DEAD DISPATCH',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Haunted postal sorting • sort or suffer',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Stats row ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bolt,
                          label: 'Best score',
                          value: '${profile.bestShiftScore}',
                          color: AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.repeat,
                          label: 'Shifts',
                          value: '${profile.totalShiftsPlayed}',
                          color: AppColors.accentGhost,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.monetization_on,
                          label: 'Coins',
                          value: '$coins',
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Primary action ──────────────────────────────────────
                  _BigPlayButton(
                    label: profile.tutorialCompleted
                        ? Strings.menuPlay
                        : Strings.menuTutorial,
                    onPressed: () => context.push(
                      profile.tutorialCompleted
                          ? AppRoutes.brief
                          : AppRoutes.tutorial,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Daily challenge ─────────────────────────────────────
                  _MenuTile(
                    icon: Icons.calendar_today,
                    label: Strings.menuDaily,
                    subtitle: 'Same seed for every player today',
                    accent: AppColors.accentGhost,
                    onTap: () => context.push(AppRoutes.daily),
                  ),

                  const SizedBox(height: 10),

                  // ── Secondary row ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _IconMenuButton(
                          icon: Icons.bolt,
                          label: 'Upgrades',
                          onTap: () => context.push(AppRoutes.upgrades),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _IconMenuButton(
                          icon: Icons.apartment,
                          label: 'Departments',
                          onTap: () => context.push(AppRoutes.departments),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _IconMenuButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => context.push(AppRoutes.settings),
                        ),
                      ),
                      if (DebugFlags.cheatsEnabled) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _IconMenuButton(
                            icon: Icons.bug_report,
                            label: 'Debug',
                            accent: AppColors.accentDanger,
                            onTap: () => context.push(AppRoutes.debug),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background decoration ────────────────────────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BgPainter());
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle diagonal stripe pattern
    final paint = Paint()
      ..color = const Color(0x07F5C04A)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }

    // Bottom glow
    final glowRect = Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x1AF5C04A), Color(0x00F5C04A)],
        ).createShader(glowRect),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({required this.label, required this.onPressed});
  final String label;
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
              color: Color(0x44F5C04A),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Color(0xFF161824), size: 28),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: accent.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

class _IconMenuButton extends StatelessWidget {
  const _IconMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppColors.textMuted,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
