import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/shift_config.dart';
import '../game/dead_dispatch_game.dart';
import '../game/game_session.dart';
import '../game/game_state.dart';
import '../../../services/analytics_service.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/combo_meter.dart';
import '../../../presentation/widgets/pause_menu.dart';

/// Hosts the Flame game widget plus the Flutter HUD overlay.
/// HUD is in Flutter (not Flame) so we get accessibility, large-text
/// scaling, and themed styling for free.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({this.dailyDateKey, super.key});

  /// Non-null = daily challenge mode.
  final String? dailyDateKey;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ShiftConfig _config;
  late final GameSession _session;
  late final DeadDispatchGame _game;
  StreamSubscription<GameEvent>? _sub;

  bool _paused = false;
  int _score = 0;
  int _combo = 0;
  double _multiplier = 1.0;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(playerProfileProvider);
    final difficulty = ref.read(difficultyServiceProvider);
    final balance = ref.read(balanceDataProvider);
    final analytics = ref.read(analyticsServiceProvider);

    _config = widget.dailyDateKey != null
        ? difficulty.buildDaily(profile, dateKey: widget.dailyDateKey)
        : difficulty.buildRegular(profile);
    _session = GameSession(config: _config, balance: balance);
    _game = DeadDispatchGame(
      config: _config,
      balance: balance,
      session: _session,
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticsServiceProvider),
      perf: ref.read(perfMonitorProvider),
    );

    analytics.logEvent(AnalyticsEvents.shiftStart, params: {
      'shiftId': _config.id,
      'isDaily': _config.isDaily,
      'targetScore': _config.targetScore,
    });

    _sub = _session.events.listen(_onEvent);
    Future<void>.delayed(const Duration(milliseconds: 200), _session.start);
  }

  void _onEvent(GameEvent e) {
    if (!mounted) return;
    switch (e) {
      case ComboChangedEvent(:final combo):
        setState(() {
          _combo = combo;
          _multiplier = _session.score.comboMultiplier;
          _score = _session.score.score;
          _remaining = _session.state.remaining;
        });
      case PackageResolvedEvent():
        setState(() => _score = _session.score.score);
      case ShiftEndedEvent(:final result):
        Navigator.of(context).pushReplacementNamed('/result', arguments: result);
      case PackageSpawnedEvent():
      case HazardStartedEvent():
      case HazardEndedEvent():
        break;
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_score / ${_config.targetScore}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ComboMeter(combo: _combo, multiplier: _multiplier),
                      IconButton(
                        icon: const Icon(Icons.pause, color: AppColors.textPrimary),
                        onPressed: _togglePause,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _config.duration.inMilliseconds == 0
                        ? 0
                        : 1 -
                            (_remaining.inMilliseconds /
                                _config.duration.inMilliseconds),
                    color: AppColors.accentGold,
                    backgroundColor: AppColors.surfaceHi,
                  ),
                ],
              ),
            ),
          ),
          if (_paused)
            PauseMenu(
              onResume: _togglePause,
              onQuit: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
        ],
      ),
    );
  }
}
