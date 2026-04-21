import 'dart:async';

import '../../../../domain/models/package.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/haptics_service.dart';
import '../game_events.dart';
import '../game_session.dart';

/// Reacts to [GameEvent]s with audio cues and haptic feedback.
/// No Flame dependency — purely a listener on the session stream.
class FeedbackSystem {
  FeedbackSystem({
    required this.session,
    required this.audio,
    required this.haptics,
  }) {
    _sub = session.events.listen(_onEvent);
  }

  final GameSession session;
  final AudioService audio;
  final HapticsService haptics;

  late final StreamSubscription<GameEvent> _sub;

  void _onEvent(GameEvent event) {
    switch (event) {
      case PackageSpawnedEvent():
        audio.playSfx(SoundId.packageSpawn);
      case PackageResolvedEvent(:final outcome):
        switch (outcome) {
          case SortOutcome.perfect:
            audio.playSfx(SoundId.packageSorted);
            haptics.trigger(HapticIntent.success);
          case SortOutcome.acceptable:
            audio.playSfx(SoundId.packageSorted);
          case SortOutcome.miss:
            audio.playSfx(SoundId.packageMissed);
            haptics.trigger(HapticIntent.failure);
          case SortOutcome.destroyed:
            audio.playSfx(SoundId.packageDestroyed);
            haptics.trigger(HapticIntent.heavyImpact);
        }
      case ComboChangedEvent(:final combo):
        if (combo > 0) audio.playSfx(SoundId.comboUp);
      case HazardStartedEvent():
        audio.playSfx(SoundId.hazardWarn);
        haptics.trigger(HapticIntent.warning);
      case HazardEndedEvent():
        audio.playSfx(SoundId.hazardClear);
      case ShiftEndedEvent():
        audio.playSfx(SoundId.shiftEnd);
      case PendingPackageChangedEvent():
        break;
    }
  }

  void dispose() => _sub.cancel();
}
