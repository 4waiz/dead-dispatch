import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../app/flavors.dart';
import '../core/env.dart';
import '../core/perf/perf_monitor.dart';
import '../core/rng/random_source.dart';
import '../core/time/clock.dart';
import '../data/repositories/daily_repository.dart';
import '../data/repositories/progression_repository.dart';
import '../data/repositories/save_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/sources/asset_preloader.dart';
import '../data/sources/config_loader.dart';
import '../data/sources/local_storage.dart';
import '../domain/balance/balance_data.dart';
import '../domain/models/player_profile.dart';
import '../domain/services/difficulty_service.dart';
import '../domain/services/economy_service.dart';
import '../domain/services/progression_service.dart';
import '../domain/services/routing_service.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../services/remote_config_service.dart';

// -----------------------------------------------------------------------------
// Env / flavor / infra
// -----------------------------------------------------------------------------

final envProvider = Provider<Env>((_) => Env.fromCompileFlags());

final flavorConfigProvider =
    Provider<FlavorConfig>((ref) => FlavorConfig.forEnv(ref.watch(envProvider)));

final perfMonitorProvider = Provider<PerfMonitor>((_) => PerfMonitor());

final clockProvider = Provider<AppClock>((_) => const SystemAppClock());

final assetPreloaderProvider =
    Provider<AssetPreloader>((_) => const AssetPreloader());

// -----------------------------------------------------------------------------
// RNG — keyed so each caller can get its own deterministic stream.
// -----------------------------------------------------------------------------

final seededRngFactoryProvider =
    Provider<RandomSource Function(int)>((_) => SeededRandomSource.new);

final systemRngProvider = Provider<RandomSource>((_) => SystemRandomSource());

// -----------------------------------------------------------------------------
// Storage / config — eagerly overridden at bootstrap.
// -----------------------------------------------------------------------------

final keyValueStorageProvider = Provider<KeyValueStorage>((_) {
  throw UnimplementedError(
    'keyValueStorageProvider must be overridden via ProviderScope at bootstrap',
  );
});

final balanceDataProvider = Provider<BalanceData>((_) {
  throw UnimplementedError(
    'balanceDataProvider must be overridden via ProviderScope at bootstrap',
  );
});

final configLoaderProvider = Provider<ConfigLoader>((_) => const ConfigLoader());

// -----------------------------------------------------------------------------
// Repositories
// -----------------------------------------------------------------------------

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => SaveRepository(ref.watch(keyValueStorageProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStorageProvider)),
);

final dailyRepositoryProvider = Provider<DailyRepository>(
  (ref) => DailyRepository(ref.watch(keyValueStorageProvider)),
);

final progressionRepositoryProvider = Provider<ProgressionRepository>(
  (ref) => ProgressionRepository(ref.watch(saveRepositoryProvider)),
);

// -----------------------------------------------------------------------------
// Domain services
// -----------------------------------------------------------------------------

final difficultyServiceProvider = Provider<DifficultyService>(
  (ref) => DifficultyService(ref.watch(balanceDataProvider)),
);

final economyServiceProvider = Provider<EconomyService>(
  (ref) => EconomyService(ref.watch(balanceDataProvider)),
);

final progressionServiceProvider = Provider<ProgressionService>(
  (ref) => ProgressionService(ref.watch(balanceDataProvider)),
);

final routingServiceProvider = Provider<RoutingService>(
  (ref) => RoutingService(ref.watch(balanceDataProvider)),
);

// -----------------------------------------------------------------------------
// Platform services — flavor-driven so release builds pick real SDKs.
// -----------------------------------------------------------------------------

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  switch (flavor.analyticsBehavior) {
    case AnalyticsBehavior.logOnly:
      return LoggingAnalyticsService();
    case AnalyticsBehavior.real:
      // TODO(phase2): swap to Firebase Analytics implementation.
      return LoggingAnalyticsService();
  }
});

final adsServiceProvider = Provider<AdsService>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  switch (flavor.adsBehavior) {
    case AdsBehavior.offlineReward:
      return OfflineRewardingAdsService();
    case AdsBehavior.disabled:
      return DisabledAdsService();
    case AdsBehavior.real:
      // TODO(phase2): swap to AdMob implementation.
      return OfflineRewardingAdsService();
  }
});

final audioServiceProvider =
    Provider<AudioService>((_) => LoggingAudioService());

final hapticsServiceProvider =
    Provider<HapticsService>((_) => FlutterHapticsService());

final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((_) => StaticRemoteConfigService());

// -----------------------------------------------------------------------------
// Router
// -----------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  return buildAppRouter(showDebugMenu: flavor.showDebugMenu);
});

// -----------------------------------------------------------------------------
// Player profile — mutable state holder. Overridden at bootstrap so the
// first build already has the loaded save.
// -----------------------------------------------------------------------------

class PlayerProfileNotifier extends StateNotifier<PlayerProfile> {
  PlayerProfileNotifier(this._repo, PlayerProfile initial) : super(initial);

  final ProgressionRepository _repo;

  Future<void> persist() async {
    await _repo.persist(state);
  }

  void mutate(void Function(PlayerProfile p) fn) {
    fn(state);
    // ignore: no_self_assignments
    state = state; // Trigger rebuilds for in-place mutation.
  }

  Future<void> reset() async {
    await _repo.wipe();
    state = PlayerProfile.fresh(state.schemaVersion);
  }

  Future<void> updateSettings(SettingsSnapshot settings) async {
    state = state.copyWithSettings(settings);
    await persist();
  }
}

final playerProfileProvider =
    StateNotifierProvider<PlayerProfileNotifier, PlayerProfile>((_) {
  throw UnimplementedError(
    'playerProfileProvider must be overridden after bootstrap loads the save',
  );
});
