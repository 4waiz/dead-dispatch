import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../domain/models/shift_config.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/pause_menu.dart';
import '../../../services/analytics_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptics_service.dart';
import '../game/board/piece.dart';
import '../game/session/puzzle_events.dart';
import '../game/session/puzzle_session.dart';
import 'widgets/board_widget.dart';
import 'widgets/clear_burst_overlay.dart';
import 'widgets/piece_tray_widget.dart';
import 'widgets/power_up_dock.dart';

/// Real block-puzzle game screen. Owns the [PuzzleSession], renders the
/// board + tray + power-ups + HUD, and wires audio/haptics by listening
/// to the session's event stream.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({this.dailyDateKey, super.key});
  final String? dailyDateKey;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ShiftConfig _config;
  late final PuzzleSession _session;
  StreamSubscription<PuzzleEvent>? _sub;

  bool _paused = false;
  int _burstTrigger = 0;
  PowerUpId? _armedPowerUp;

  late AudioService _audio;
  late HapticsService _haptics;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    final balance = ref.read(balanceDataProvider);
    _audio = ref.read(audioServiceProvider);
    _haptics = ref.read(hapticsServiceProvider);

    _config = widget.dailyDateKey != null
        ? difficulty.buildDaily(profile, dateKey: widget.dailyDateKey)
        : difficulty.buildClassic(profile);

    _session = PuzzleSession(
      config: _config,
      balance: balance,
      profile: profile,
    );

    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(
      AnalyticsEvents.shiftStart,
      params: {
        'shiftId': _config.id,
        'isDaily': _config.isDaily,
        'targetScore': _config.targetScore,
      },
    );

    _sub = _session.events.listen(_onEvent);
    _session.start();
  }

  void _onEvent(PuzzleEvent event) {
    if (!mounted) return;
    switch (event) {
      case PiecePickedUpEvent():
        unawaited(_audio.playSfx(SoundId.piecePickUp));
        unawaited(_haptics.trigger(HapticIntent.selection));
      case PiecePlacedEvent(:final linesCleared, :final coinDelta):
        unawaited(_audio.playSfx(SoundId.piecePlaced));
        unawaited(_haptics.trigger(HapticIntent.uiTap));
        if (coinDelta > 0) {
          unawaited(_audio.playSfx(SoundId.coinSparkle));
        }
        setState(() {});
        if (linesCleared > 0) {
          setState(() => _burstTrigger++);
        }
      case InvalidDropEvent():
        unawaited(_audio.playSfx(SoundId.invalidDrop));
        unawaited(_haptics.trigger(HapticIntent.failure));
      case LinesClearedEvent():
        unawaited(_audio.playSfx(SoundId.linesCleared));
        unawaited(_haptics.trigger(HapticIntent.success));
      case ComboChangedEvent(:final combo):
        if (combo >= 2) {
          unawaited(_audio.playSfx(SoundId.comboChime));
          unawaited(_haptics.trigger(HapticIntent.heavyImpact));
        }
        setState(() {});
      case BoardClearedEvent():
        unawaited(_audio.playSfx(SoundId.comboChime));
        unawaited(_haptics.trigger(HapticIntent.heavyImpact));
      case PowerUpUsedEvent():
        setState(() {
          _armedPowerUp = null;
        });
      case QueueRefilledEvent():
        setState(() {});
      case ShiftTargetReachedEvent():
        unawaited(_audio.playSfx(SoundId.reward));
      case GameOverEvent(:final result):
        unawaited(_audio.playSfx(SoundId.gameOverSigh));
        unawaited(_haptics.trigger(HapticIntent.warning));
        context.pushReplacement(AppRoutes.result, extra: result);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _session.dispose();
    super.dispose();
  }

  void _togglePause() => setState(() => _paused = !_paused);

  bool _onPlace(Piece piece, int row, int col) {
    return _session.tryPlace(
      pieceId: piece.id,
      anchorRow: row,
      anchorCol: col,
    );
  }

  void _onPickUp(Piece piece) {
    _session.onPiecePickedUp(piece);
  }

  bool _canFit(Piece piece) {
    final size = _session.state.board.size;
    for (var r = 0; r <= size - piece.rows; r++) {
      for (var c = 0; c <= size - piece.cols; c++) {
        if (_session.state.board.canPlace(piece, r, c)) return true;
      }
    }
    return false;
  }

  void _onStampBlast() {
    setState(() {
      _armedPowerUp = _armedPowerUp == PowerUpId.stampBlast
          ? null
          : PowerUpId.stampBlast;
    });
  }

  void _onGhostSwap() {
    _session.useGhostSwap();
  }

  @override
  Widget build(BuildContext context) {
    final state = _session.state;
    final profile = ref.watch(playerProfileProvider);

    final mediaWidth = MediaQuery.of(context).size.width;
    // Leave room for the gutter; the board occupies the inner width.
    final boardSide = mediaWidth - 32;
    final cellSize = (boardSide / state.board.size).floorToDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _Hud(
                    score: state.score,
                    bestScore: profile.bestShiftScore,
                    combo: state.combo,
                    coins: state.coins,
                    target: _config.targetScore,
                    isDaily: _config.isDaily,
                    onPause: _togglePause,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTapDown: _armedPowerUp == PowerUpId.stampBlast
                            ? (details) => _handleStampBlastTap(
                                  details.localPosition,
                                  cellSize,
                                )
                            : null,
                        child: BoardWidget(
                          board: state.board,
                          cellSize: cellSize,
                          onPlace: _onPlace,
                          onPieceHover: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PowerUpDock(
                    stampBlastCharges: state.stampBlastCharges,
                    ghostSwapCharges: state.ghostSwapCharges,
                    armedPowerUp: _armedPowerUp,
                    onStampBlast: _onStampBlast,
                    onGhostSwap: _onGhostSwap,
                  ),
                  const SizedBox(height: 10),
                  PieceTrayWidget(
                    pieces: state.queue,
                    cellSize: (cellSize * 0.55).clamp(18.0, 48.0),
                    canFit: _canFit,
                    onPickUp: _onPickUp,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          ClearBurstOverlay(
            trigger: _burstTrigger,
            reducedMotion: profile.settings.reducedMotion,
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

  void _handleStampBlastTap(Offset local, double cellSize) {
    final row = (local.dy / cellSize).floor();
    final col = (local.dx / cellSize).floor();
    if (_session.useStampBlast(row: row, col: col)) {
      setState(() {});
    }
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.bestScore,
    required this.combo,
    required this.coins,
    required this.target,
    required this.isDaily,
    required this.onPause,
  });

  final int score;
  final int bestScore;
  final int combo;
  final int coins;
  final int target;
  final bool isDaily;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: Row(
        children: [
          _HudStat(
            label: 'SCORE',
            value: '$score',
            color: AppColors.accentGold,
          ),
          const SizedBox(width: 12),
          _HudStat(
            label: 'BEST',
            value: '$bestScore',
            color: AppColors.accentGhost,
          ),
          const SizedBox(width: 12),
          _HudStat(
            label: 'COMBO',
            value: '×$combo',
            color: combo >= 2 ? AppColors.goldenPop : AppColors.textMuted,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: AppColors.accentGold,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.pause_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onPause,
          ),
        ],
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}
