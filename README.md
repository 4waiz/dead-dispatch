# Dead Dispatch

A hybrid-casual puzzle/management game set in a haunted postal sorting office. You are the night-shift dispatcher in a centuries-old mailroom where parcels misbehave: priority mail demands stamps, fragile boxes shatter on bad routes, decaying mail rots before your eyes, and ghost mail drifts past the rules entirely. Survive timed shifts by tapping the right lane for each parcel before it falls off the belt — earn coins, restore haunted departments of the dead letter office, and chase a daily challenge that's deterministic worldwide.

Built with **Flutter + Flame**.

---

## The game in one minute

- **The loop.** A shift lasts ~75 seconds. Parcels stream down a conveyor toward a gate. When a parcel reaches the gate it waits ~6 seconds for you to tap one of the active lane buttons (north / south / vault / cold / void / review / shred / incinerator). Pick well and your combo multiplier climbs (up to **3.0×**); fumble and the combo resets and the score takes a hit.
- **Package types matter.** Each of the 8 types (`standard`, `priority`, `fragile`, `frozen`, `mislabeled`, `duplicate`, `decaying`, `ghost`) has its own correct lane, score, belt speed, and rule. Priority parcels need a **stamp** (limited per shift — 3 default, 6 with the `doubleStamps` modifier) for a perfect rating; mislabeled mail goes to **review** unless stamped; duplicates are *meant* to be shredded; decaying mail goes to the **incinerator** before it rots past 95%; fragile mail in the wrong lane is **destroyed**.
- **Hazards.** Every 8–18 seconds the office misbehaves: `beltJam` (freezes routing timer), `powerFlicker`, `misrouteChain`, `surgeRush` (2× spawn rate), `blackout`, `vipWave` (only priority + ghost spawn). Hazards unlock progressively with player level.
- **Meta-progression.** Coins earned per shift fund **persistent upgrades** (`Greased Bearings`, `Ink Reserves`, `Phantom Intern`, `Padded Liners`, etc.) and **department restoration** — each restored room of the haunted building unlocks new package types or modifiers. A daily challenge runs off a deterministic seed: same date → same parcel order on every device.
- **Difficulty curve.** `progressionLevel = (totalShifts ÷ 3) + (restoredDepartments × 2)`. Target score grows as `baseTargetScore × 1.18^level`. Spawn interval decays linearly down to 550 ms minimum. New package types and hazards open up at fixed level breakpoints.

---

## Technical overview

### Stack

| Concern | Tool |
|---|---|
| App framework | Flutter (Dart ≥ 3.4, Flutter ≥ 3.22) |
| Game engine | [`flame`](https://pub.dev/packages/flame) ^1.18 + `flame_audio` ^2.10 |
| State / DI | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) ^2.5 |
| Routing | [`go_router`](https://pub.dev/packages/go_router) ^14.2 |
| Persistence | `shared_preferences` ^2.2 |
| Determinism | `clock` (test-injectable wall clock) + bespoke `SeededRandom` (xorshift32) |
| Targets | Android, iOS, Web, Windows, macOS, Linux |

### Layered architecture

The codebase is strictly layered. Each layer may depend only **inward** (toward `core` + `domain`).

```
presentation/   Flutter screens, widgets, theme       ← features/*/presentation
game/           Flame world: systems, components       ← features/gameplay/game
services/       Platform adapters (ads, audio,
                analytics, haptics, remote config)
data/           Repositories, local storage,
                config loader, save migrations
domain/         Pure Dart models + services
                (NO Flutter, NO Flame)
core/           Logger, env, failures, debug flags,
                perf monitor, clock, RNG sources
```

DI is centralised in [lib/di/providers.dart](lib/di/providers.dart). All async "must succeed" init (storage open, balance JSON load, profile load) runs in [lib/app/bootstrap.dart](lib/app/bootstrap.dart) and overrides the throwing default providers before `runApp`. Any boot failure surfaces a visible error screen rather than a blank app.

### Code map

```
lib/
├── main.dart                       ← single-line entrypoint → bootstrap()
├── app/
│   ├── bootstrap.dart              ← async init, ProviderScope overrides
│   ├── app.dart                    ← MaterialApp.router root
│   ├── app_router.dart             ← go_router config (11 routes)
│   ├── app_theme.dart, app_lifecycle.dart, flavors.dart
├── core/
│   ├── perf/perf_monitor.dart      ← rolling frame-time sampler
│   ├── rng/random_source.dart      ← SeededRandomSource + SystemRandomSource
│   ├── time/clock.dart             ← AppClock abstraction
│   ├── logger.dart, env.dart, debug_flags.dart, failures.dart, result.dart, constants.dart
├── domain/                         ← pure Dart, framework-free
│   ├── balance/                    ← BalanceData, BalanceProvider
│   ├── models/                     ← GamePackage, PackageType, Hazard,
│   │                                  ShiftConfig, ShiftResult, PlayerProfile,
│   │                                  Wallet, OwnedUpgrade, Department, …
│   └── services/                   ← ScoreService, RoutingService,
│                                      DifficultyService, EconomyService,
│                                      ProgressionService, SeededRandom, DailySeed
├── data/
│   ├── sources/                    ← SharedPrefsStorage, ConfigLoader, AssetPreloader
│   ├── repositories/               ← SaveRepository, ProgressionRepository,
│   │                                  SettingsRepository, DailyRepository
│   └── migrations/save_migrator.dart  ← versioned save migrations
├── services/                       ← AdsService, AudioService, HapticsService,
│                                      AnalyticsService, RemoteConfigService
├── di/providers.dart               ← Riverpod composition root
├── presentation/                   ← shared widgets, theme, gameplay copy
└── features/
    ├── splash/, menu/, tutorial/, shift_brief/,
    ├── shift_result/, upgrades/, meta/ (departments),
    ├── daily_challenge/, settings/, debug/
    └── gameplay/
        ├── presentation/game_screen.dart        ← Flutter HUD + GameWidget host
        └── game/
            ├── dead_dispatch_game.dart          ← FlameGame subclass
            ├── game_session.dart                ← shift orchestrator (events + state)
            ├── game_state.dart                  ← immutable runtime snapshot
            ├── game_events.dart                 ← sealed GameEvent hierarchy
            ├── systems/
            │   ├── spawner_system.dart          ← package spawning + jitter
            │   ├── routing_system.dart          ← gate detection + timeout
            │   ├── hazard_system.dart           ← weighted hazard scheduler
            │   └── feedback_system.dart         ← SFX + haptics on session events
            └── components/
                ├── belt_component.dart          ← scrolling conveyor
                ├── package_component.dart       ← parcel sprite/rect
                ├── background_component.dart, hazard_overlay_component.dart,
                  particle_burst.dart, score_popup.dart
```

### Runtime data flow — one shift

```
User taps "Play"
   │
   ▼
GameScreen.initState():
   ├─ DifficultyService.buildRegular(profile) → ShiftConfig
   ├─ new GameSession(config, balance)
   └─ new DeadDispatchGame(session, balance, audio, haptics, perf, routingService)
   │
   ▼
Flame onLoad: registers BackgroundComponent + BeltComponent + HazardOverlay,
              instantiates SpawnerSystem / HazardSystem / RoutingSystem /
              FeedbackSystem, then session.start().
   │
   ▼
Flame update(dt) every frame:
   1. perf.record(dt × 1000)
   2. session.tick(dt) — advances elapsed, fires ShiftEndedEvent on timeout
   3. SpawnerSystem.tick → maybe spawn (respects maxConcurrent, surgeRush 2× rate)
   4. HazardSystem.tick  → expire active hazards, maybe trigger new (weighted by
                            inverse-severity, sampled with SeededRandom)
   5. RoutingSystem.tick → detect package-at-gate, arm 6 s timeout,
                            on timeout auto-miss; on player lane tap, call
                            RoutingService.resolve() → SortOutcome
   6. session.onPackageResolved → ScoreService.registerOutcome,
                                   emits PackageResolvedEvent + ComboChangedEvent
   7. FeedbackSystem (listening on session.events) fires SFX + haptics
   │
   ▼
session emits ShiftEndedEvent → GameScreen pushReplacement(/result, result)
   │
   ▼
ShiftResultScreen: ProgressionService.recordShift, EconomyService.payoutForShift,
                   optional rewarded ad for doubled coins / mystery parcel,
                   SaveRepository.save
```

### Key design decisions

1. **Domain is framework-free.** Nothing under `lib/domain/` imports `package:flutter` or `package:flame`. Scoring, routing, difficulty, economy, and progression are unit-testable in milliseconds.
2. **Balancing is data, not code.** Every tunable lives in `assets/config/*.json` (`balance.json`, `packages.json`, `hazards.json`, `upgrades.json`, `departments.json`, `shifts.json`). `BalanceProvider` assembles a `BalanceData` value object at boot. Future remote-config swap is one provider override.
3. **Per-run ≠ persistent.** Per-run boosts live in `ShiftConfig.modifiers` (e.g. `doubleStamps`). Persistent upgrades live in `PlayerProfile.upgrades`. The boundary is deliberate — mixing them was called out in the spec.
4. **Deterministic daily challenges.** `DailySeed.seedFor(dateKey)` is FNV-1a over the YYYY-MM-DD string. That seed feeds a `SeededRandom` (xorshift32) that drives every spawn, hazard, and modifier roll. Same date → identical shift on every device on Earth.
5. **Service abstractions for everything platform-shaped.** `AdsService`, `AnalyticsService`, `AudioService`, `HapticsService`, `RemoteConfigService` each have an interface + a default offline stub (`LoggingAnalyticsService`, `OfflineRewardingAdsService`, etc.). The game is fully playable offline; release flavors swap in real SDKs via [lib/app/flavors.dart](lib/app/flavors.dart).
6. **Versioned save migrations.** `AppConstants.saveSchemaVersion` + `SaveMigrator._migrations` — bump the version, register a transformer, test every step.
7. **Allocation-free hot paths.** `spawner_system.dart`, `routing_system.dart`, `hazard_system.dart` avoid per-frame closures and list allocations. Target: ≤ 16.6 ms/frame on a Pixel 4a. `PerfMonitor` exposes a rolling histogram on the debug screen.

### Game-loop contract

| Component | Owns | Talks to |
|---|---|---|
| `DeadDispatchGame` | The Flame world, component list, package lifecycle | systems, `GameSession` |
| `GameSession` | Authoritative `GameState`, `ScoreService`, `SeededRandom`, event stream | every system + `GameScreen` |
| `SpawnerSystem` | When the next package appears, which type | session.rng, game.addPackage |
| `RoutingSystem` | Gate detection, 6 s routing timeout, calls `RoutingService.resolve` | session, game, RoutingService |
| `HazardSystem` | Hazard schedule (8–18 s cadence, weighted-by-inverse-severity sampling), expiry | session, balance |
| `FeedbackSystem` | SFX + haptics on `GameEvent` stream | AudioService, HapticsService |
| `GameScreen` (Flutter) | HUD (score, timer, combo, stamps), lane buttons, pause menu | session.events, game.onLaneTapped/onStampTapped |

`GameSession` publishes a sealed `GameEvent` stream — `PackageSpawnedEvent`, `PackageResolvedEvent`, `ComboChangedEvent`, `HazardStartedEvent`, `HazardEndedEvent`, `PendingPackageChangedEvent`, `ShiftEndedEvent`. The HUD and feedback layer are pure subscribers; they never mutate game state.

### Persistence

A single `PlayerProfile` JSON blob is the root: wallet, owned upgrades, restored departments, daily-challenge attempts, settings, tutorial flag, totals, best score. Atomicity by design — one write per save, no partial states. Settings, daily attempts, and progression each have a thin repository that delegates to `SaveRepository`. Migrations are explicit and tested ([test/data/save_migrator_test.dart](test/data/save_migrator_test.dart)).

### Testing

| Concern | Test file |
|---|---|
| Seeded RNG determinism | [test/domain/seeded_random_test.dart](test/domain/seeded_random_test.dart) |
| Daily-seed stability across dates | [test/domain/daily_seed_test.dart](test/domain/daily_seed_test.dart) |
| Score + combo math | [test/domain/score_service_test.dart](test/domain/score_service_test.dart) |
| Economy: purchases, mystery roll, payouts | [test/domain/economy_service_test.dart](test/domain/economy_service_test.dart) |
| Difficulty curve, type/hazard unlock order | [test/domain/difficulty_service_test.dart](test/domain/difficulty_service_test.dart) |
| Routing for every package type | [test/domain/routing_service_test.dart](test/domain/routing_service_test.dart) |
| Progression / department gating | [test/domain/progression_service_test.dart](test/domain/progression_service_test.dart) |
| Model JSON round-trip | [test/domain/models_serialization_test.dart](test/domain/models_serialization_test.dart) |
| Save migration v0 → vN | [test/data/save_migrator_test.dart](test/data/save_migrator_test.dart) |

Widget and integration tests are intentionally minimal — domain coverage surfaces regressions fastest.

---

## Balancing knobs (the file you'll touch most)

[assets/config/balance.json](assets/config/balance.json) — the core economy & shift pacing.

```jsonc
{
  "shifts": {
    "baseDurationMs": 75000,
    "baseSpawnIntervalMs": 1800,
    "minSpawnIntervalMs": 550,
    "spawnIntervalDecayPerLevelMs": 60,
    "baseTargetScore": 600,
    "targetScoreGrowth": 1.18,
    "maxConcurrentBase": 4,
    "maxConcurrentGrowthEvery": 3
  },
  "economy": {
    "coinPerScorePoint": 0.10,
    "perfectBonus": 25,
    "comboMultiplierStep": 0.05,
    "comboMultiplierCap": 3.0,
    "dailyCompletionBonus": 100,
    "failureForgivenessRefund": 0.5,
    "mysteryParcelMin": 50,
    "mysteryParcelMax": 250
  }
}
```

JSON edits are hot-reloadable in dev — `flutter run`, save the file, hot-restart.

For richer guidance (adding a new package type, adding a new hazard, monetisation knobs) see [docs/BALANCING.md](docs/BALANCING.md). For the layered architecture in depth see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Running the game

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows     # or -d chrome, -d <android-device-id>
```

Manual smoke test:

1. Splash → Main Menu shows wallet + best score.
2. First launch routes to the 4-slide Tutorial.
3. Shift Brief → tap **Play**.
4. Belt scrolls, packages spawn, lane buttons appear when a parcel reaches the gate, the stamp button consumes stamps, the combo meter climbs on perfects, hazards fire visually (jam light, blackout vignette).
5. Timer hits zero → Shift Result with score breakdown.
6. Rewarded-ad stub doubles coins.
7. Upgrades / Departments persist across app restart.
8. Daily Challenge: same seed on two launches → same parcel order (determinism check).

---

## Status

The codebase is at the **playable v1** mark per [PLAN.md](PLAN.md): the Flame gameplay world, score loop, hazards, daily challenge, upgrades, departments, settings, persistence, and the full menu chain are wired end-to-end. Real AdMob / Firebase / final art + audio swaps are flavor-gated TODOs at [lib/di/providers.dart:127-138](lib/di/providers.dart#L127-L138).
