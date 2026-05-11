import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../domain/balance/balance_data.dart';
import '../../../domain/models/package.dart';
import '../../../domain/models/shift_config.dart';
import '../../../presentation/gameplay_copy.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/combo_meter.dart';
import '../../../presentation/widgets/pause_menu.dart';
import '../../../services/analytics_service.dart';
import '../game/dead_dispatch_game.dart';
import '../game/game_events.dart';
import '../game/game_session.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({this.dailyDateKey, super.key});

  final String? dailyDateKey;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final ShiftConfig _config;
  late final GameSession _session;
  late final DeadDispatchGame _game;
  late final BalanceData _balance;
  late final AnimationController _routingTimer;
  StreamSubscription<GameEvent>? _sub;

  bool _paused = false;
  int _score = 0;
  int _combo = 0;
  double _multiplier = 1.0;
  Duration _remaining = Duration.zero;
  int _stamps = 0;
  GamePackage? _pendingPackage;

  @override
  void initState() {
    super.initState();
    _routingTimer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    final profile = ref.read(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    _balance = ref.read(balanceDataProvider);
    final analytics = ref.read(analyticsServiceProvider);

    _config = widget.dailyDateKey != null
        ? difficulty.buildDaily(profile, dateKey: widget.dailyDateKey)
        : difficulty.buildRegular(profile);

    _session = GameSession(config: _config, balance: _balance);
    _stamps = _session.state.stamps;

    _game = DeadDispatchGame(
      session: _session,
      balance: _balance,
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticsServiceProvider),
      perf: ref.read(perfMonitorProvider),
      routingService: ref.read(routingServiceProvider),
    );

    analytics.logEvent(
      AnalyticsEvents.shiftStart,
      params: {
        'shiftId': _config.id,
        'isDaily': _config.isDaily,
        'targetScore': _config.targetScore,
      },
    );

    _remaining = _config.duration;
    _sub = _session.events.listen(_onEvent);
  }

  void _onEvent(GameEvent e) {
    if (!mounted) return;
    switch (e) {
      case ComboChangedEvent(:final combo, :final multiplier):
        setState(() {
          _combo = combo;
          _multiplier = multiplier;
          _score = _session.score.score;
          _remaining = _session.state.remaining;
          _stamps = _session.state.stamps;
        });
      case PackageResolvedEvent():
        setState(() {
          _score = _session.score.score;
          _remaining = _session.state.remaining;
        });
      case PendingPackageChangedEvent(:final pkg):
        setState(() {
          _pendingPackage = pkg;
          _stamps = _session.state.stamps;
        });
        if (pkg != null) {
          _routingTimer.forward(from: 0);
        } else {
          _routingTimer.stop();
        }
      case ShiftEndedEvent(:final result):
        context.pushReplacement(AppRoutes.result, extra: result);
      case PackageSpawnedEvent():
      case HazardStartedEvent():
      case HazardEndedEvent():
        break;
    }
  }

  @override
  void dispose() {
    _routingTimer.dispose();
    _sub?.cancel();
    _session.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _session.pause();
    } else {
      _session.resume();
    }
  }

  // Lane keys for all package types the current shift allows
  List<String> get _activeLanes {
    final seen = <String>{};
    final lanes = <String>[];
    for (final type in _config.allowedTypes) {
      final lane = _balance.packageOf(type).lane;
      if (seen.add(lane)) lanes.add(lane);
    }
    return lanes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Column(
              children: [
                _buildHud(),
                const Spacer(),
                _buildRoutingPanel(),
              ],
            ),
          ),
          if (_paused)
            PauseMenu(
              onResume: _togglePause,
              onQuit: () => context.go(AppRoutes.menu),
            ),
        ],
      ),
    );
  }

  Widget _buildHud() {
    final elapsed = _config.duration - _remaining;
    final timeProgress = _config.duration.inMilliseconds == 0
        ? 0.0
        : elapsed.inMilliseconds / _config.duration.inMilliseconds;
    final scoreProgress = _config.targetScore == 0
        ? 0.0
        : (_score / _config.targetScore).clamp(0.0, 1.0);
    final secsLeft = _remaining.inSeconds;
    final timeUrgent = secsLeft <= 15;

    return Container(
      color: AppColors.background.withValues(alpha: 0.92),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_score',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          ' / ${_config.targetScore}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: scoreProgress,
                        minHeight: 5,
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.surfaceHi,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Timer
              Column(
                children: [
                  Text(
                    '${secsLeft ~/ 60}:${(secsLeft % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: timeUrgent
                          ? AppColors.accentDanger
                          : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: 1.0 - timeProgress,
                        minHeight: 5,
                        color: timeUrgent
                            ? AppColors.accentDanger
                            : AppColors.accentOk,
                        backgroundColor: AppColors.surfaceHi,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              ComboMeter(combo: _combo, multiplier: _multiplier),
              IconButton(
                icon: const Icon(
                  Icons.pause_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                onPressed: _togglePause,
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRoutingPanel() {
    if (_pendingPackage == null) return const SizedBox(height: 8);
    final pkg = _pendingPackage!;
    final pkgColor = AppColors.forPackage(pkg.type);
    final lanes = _activeLanes;
    final instruction = routingInstructionFor(
      type: pkg.type,
      balance: _balance,
      stamped: pkg.stamped,
    );

    return AnimatedBuilder(
      animation: _routingTimer,
      builder: (context, _) {
        final countdown = 1.0 - _routingTimer.value;
        final urgency = _routingTimer.value > 0.7;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: urgency ? AppColors.accentDanger : pkgColor,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Countdown bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: countdown,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceHi,
                  color: urgency ? AppColors.accentDanger : pkgColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Package preview chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pkgColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: pkgColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      packageDisplayName(pkg.type).toUpperCase(),
                      style: TextStyle(
                        color: pkgColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (_stamps > 0)
                    _StampButton(
                      stamps: _stamps,
                      onTap: () => setState(() {
                        _game.onStampTapped();
                        _stamps = _session.state.stamps;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lanes
                    .map(
                      (lane) => _LaneButton(
                        lane: lane,
                        onTap: () => _game.onLaneTapped(lane),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _LaneButton extends StatelessWidget {
  const _LaneButton({required this.lane, required this.onTap});

  final String lane;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E334E), Color(0xFF232840)],
          ),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33F5C04A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          laneDisplayName(lane).toUpperCase(),
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _StampButton extends StatelessWidget {
  const _StampButton({required this.stamps, required this.onTap});

  final int stamps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accentGold),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.approval, color: AppColors.accentGold, size: 16),
            const SizedBox(width: 4),
            Text(
              '$stamps',
              style: const TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
