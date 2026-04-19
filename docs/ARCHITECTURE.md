# Architecture

Dead Dispatch is organised in layers. Each layer has a single responsibility
and may only depend *inward* (toward `core` + `domain`).

```
┌─────────────────────────────────────────────┐
│ presentation  (Flutter screens + widgets)   │
├─────────────────────────────────────────────┤
│ game          (Flame world: components,     │
│                systems, effects, input)     │
├─────────────────────────────────────────────┤
│ services      (platform adapters behind     │
│                interfaces: ads, audio,      │
│                analytics, haptics)          │
├─────────────────────────────────────────────┤
│ data          (repositories, local storage, │
│                config loading, migrations)  │
├─────────────────────────────────────────────┤
│ domain        (pure Dart models + services. │
│                NO Flutter, NO Flame.)       │
├─────────────────────────────────────────────┤
│ core          (logger, env, failures,       │
│                debug flags, perf monitor)   │
└─────────────────────────────────────────────┘
```

DI lives in [`lib/di/providers.dart`](../lib/di/providers.dart) using
[`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod). Providers
are overridden at bootstrap once the async storage + config loads resolve.

## Key design rules

1. **Domain is framework-free.** Never import `package:flutter/*` or
   `package:flame/*` under `lib/domain/`. That keeps scoring, difficulty,
   routing, and economy logic unit-testable in milliseconds.

2. **Balancing data is not code.** All tunables live in `assets/config/*.json`.
   The `BalanceProvider` assembles `BalanceData`; `ConfigLoader` hydrates it
   from bundled assets today and could later pull from remote config.

3. **Service abstractions for anything platform-shaped.** Ads, analytics,
   audio, haptics, and remote config all have interface + default stub
   implementations. The game is fully playable offline with the stubs.

4. **Per-run ≠ persistent.** Per-run boosts live inside `ShiftConfig`.
   Persistent upgrades live in `PlayerProfile.upgrades`. Mixing them was
   explicitly called out in the spec; don't regress that boundary.

5. **Deterministic daily challenges.** The daily seed is derived from
   `DailySeed.seedFor(dateKey)` (FNV-1a), fed into `SeededRandom`
   (xorshift32). Same date → same shift on every device.

6. **Save migrations are explicit.** Bump
   `AppConstants.saveSchemaVersion` and add a transformer in
   `SaveMigrator._migrations`. Unit test every step.

## Data flow (single shift)

```
User taps "Play"
    │
    ▼
GameScreen.initState()
    │
    ├─ DifficultyService.buildRegular(profile) → ShiftConfig
    ├─ new GameSession(config, balance)
    ├─ new DeadDispatchGame(session, balance, audio, haptics, perf)
    │
    ▼
Flame onLoad: SpawnerSystem, HazardSystem, RoutingSystem, FeedbackSystem
    │
    ▼
Flame update():
    1. session.tick(dt)
    2. SpawnerSystem.maybeSpawn() → GamePackage
    3. HazardSystem.maybeTrigger() → ActiveHazard
    4. Packages cross belt end → RoutingSystem.resolve() → SortOutcome
    5. session.resolvePackage() → ScoreService registers the outcome
    6. FeedbackSystem fires particles / shake / haptic / sfx
    │
    ▼
Session emits ShiftEndedEvent → GameScreen pushes ShiftResultScreen
    │
    ▼
ShiftResultScreen settles the shift:
    - ProgressionService.recordShift
    - EconomyService.payoutForShift + award
    - Optional rewarded ad for double / mystery parcel
    - SaveRepository.save
```

## Testing strategy

| Concern | Where | Test file |
|---|---|---|
| Determinism of seeded RNG | `test/domain/seeded_random_test.dart` | ✅ |
| Daily seed stability | `test/domain/daily_seed_test.dart` | ✅ |
| Score + combo math | `test/domain/score_service_test.dart` | ✅ |
| Economy purchases / mystery roll | `test/domain/economy_service_test.dart` | ✅ |
| Difficulty curve | `test/domain/difficulty_service_test.dart` | ✅ |
| Routing outcomes for every package type | `test/domain/routing_system_test.dart` | ✅ |
| Save migration v0 → v1 | `test/data/save_migrator_test.dart` | ✅ |

Widget and integration tests are seeded but intentionally minimal for v1 —
prioritise domain tests, because they surface regressions fastest.

## Performance budgets

- Target ≤16.6 ms/frame on mid-range Android (Pixel 4a / Moto G).
- `PerfMonitor` samples rolling frame times; debug builds expose it via
  the `/debug` screen.
- Avoid per-frame allocations in `lib/game/systems/*`. The spawner/routing
  loops are already allocation-free hot paths.

## Next steps after v1

- Real AdMob adapter behind `AdsService`.
- Firebase Crashlytics + Analytics behind `AnalyticsService`.
- Art/audio asset pipeline in `assets/images/` + `assets/audio/`.
- Proper `.arb` localisation (the string indirection is already in place).
- More hazards: implement the blackout + VIP wave visual states in the
  Flame world (domain support is already here).
