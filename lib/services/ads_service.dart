import 'dart:async';

import '../core/failures.dart';
import '../core/logger.dart';
import '../core/result.dart';

/// Where the player is when an ad is requested. Each placement maps to a
/// player-meaningful reward. Adding a placement = adding to this enum.
enum AdPlacement {
  continueAfterFailure,
  doubleShiftReward,
  mysteryParcel,
  instantRoomRepair,
  speedUpUpgrade;

  String get key => name;
}

/// Outcome of a single ad request.
sealed class AdOutcome {
  const AdOutcome();
}

class AdRewardGranted extends AdOutcome {
  const AdRewardGranted();
}

class AdDismissed extends AdOutcome {
  const AdDismissed();
}

class AdUnavailable extends AdOutcome {
  const AdUnavailable(this.reason);
  final String reason;
}

/// Public interface every screen calls. The default implementation is a
/// stub that always grants the reward — that keeps the game playable
/// offline and makes it trivial to A/B test ads-on/ads-off later.
abstract class AdsService {
  Future<void> initialize();

  /// Whether a rewarded ad is available for [placement]. Used to decide
  /// whether to show the rewarded-ad button at all.
  Future<bool> isRewardedReady(AdPlacement placement);

  /// Show the rewarded ad. Resolves to a typed outcome the caller can
  /// branch on. Never throws — wraps failures in [AdUnavailable].
  Future<Result<AdOutcome>> showRewarded(AdPlacement placement);
}

/// Always-grants stub. Safe to ship in v1 — the game still feels generous
/// and we can swap to AdMob without touching screens.
class OfflineRewardingAdsService implements AdsService {
  final AppLogger _log = AppLogger('Ads');

  @override
  Future<void> initialize() async {
    _log.i('Offline ads service ready (no real ads will be shown).');
  }

  @override
  Future<bool> isRewardedReady(AdPlacement placement) async => true;

  @override
  Future<Result<AdOutcome>> showRewarded(AdPlacement placement) async {
    _log.i('Granting offline reward for ${placement.key}.');
    // Simulate a short delay so the UI can play a "loading ad" animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Ok(AdRewardGranted());
  }
}

/// Disabled implementation — useful for kid-mode / no-ads SKUs / tests.
class DisabledAdsService implements AdsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isRewardedReady(AdPlacement placement) async => false;

  @override
  Future<Result<AdOutcome>> showRewarded(AdPlacement placement) async {
    return const Err(AdFailure('Ads disabled'));
  }
}
