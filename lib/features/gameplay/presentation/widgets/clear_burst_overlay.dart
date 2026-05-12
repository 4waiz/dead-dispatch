import 'package:flutter/material.dart';

import '../../../../presentation/theme/colors.dart';

/// Brief gold + DISPATCHED! burst rendered when a [LinesClearedEvent]
/// fires. Honours [SettingsSnapshot.reducedMotion] — when true, the
/// burst is suppressed and only a faint colour pulse remains.
class ClearBurstOverlay extends StatefulWidget {
  const ClearBurstOverlay({
    required this.trigger,
    required this.reducedMotion,
    super.key,
  });

  /// Increment to fire a new burst. The widget watches the value via
  /// didUpdateWidget so any non-zero change replays the animation.
  final int trigger;
  final bool reducedMotion;

  @override
  State<ClearBurstOverlay> createState() => _ClearBurstOverlayState();
}

class _ClearBurstOverlayState extends State<ClearBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant ClearBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          if (t == 0) return const SizedBox.shrink();
          final opacity = (1.0 - t).clamp(0.0, 1.0);
          final scale = widget.reducedMotion ? 1.0 : (0.8 + 0.4 * t);
          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldenPop.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.6),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'DISPATCHED!',
                    style: TextStyle(
                      color: Color(0xFF161824),
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
